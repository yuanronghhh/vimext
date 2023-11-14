function vimext#proto#Create(name) abort
let s:mi_cmd = {
      \ "name": "mi",
      \ "Arguments": "-exec-arguments",
      \ "Break": "-break-insert",
      \ "Clear": "-break-delete",
      \ "Run": "-exec-run",
      \ "Step": "-exec-step",
      \ "Next": "-exec-next",
      \ "Finish": "-exec-finish",
      \ "Interrupt": "-exec-interrupt",
      \ "Continue": "-exec-continue",
      \ "Until": "-exec-until",
      \ "Frame": "-interpreter-exec mi frame",
      \ "Console": "-interpreter-exec console",
      \ "Source": "source",
      \ "Set": "-gdb-set",
      \ "Exit": "-gdb-exit",
      \ "SaveBreakoints": "save breakpoints",
      \ "DecodeLine": function("s:MIDecodeLine"),
      \ "ProcessInput": function("s:ProcessInput"),
      \ "ProcessMsg": function("s:ProcessMsg"),
      \ "Dispose": function("s:Dispose")
      \ }

  let l:self = v:null
  if a:name == "mi"
     let l:self = s:mi_cmd
  endif

  return l:self
endfunction

function s:ParseInputArgs(cmd)
  let l:nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(l:nameIdx) <= 2
    return ""
  endif

  return l:nameIdx[2]
endfunction

function s:ProcessInput(self, cmd)
  let l:info = [0, a:cmd, ""]

  if a:cmd == "q"
        \ || a:cmd == "quit"
        \ || a:cmd == "exit"
    let l:info[0] = 1
    let l:info[1] = a:self.Exit
    let l:info[2] = s:ParseInputArgs(a:cmd)
    return l:info
  endif

  if a:cmd == "s"
        \ || a:cmd == "step"
    let l:info[0] = 2
    let l:info[1] = a:self.Step
    let l:info[2] = s:ParseInputArgs(a:cmd)
    return l:info
  endif

  if a:cmd == "fin"
        \ || a:cmd == "finish"
    return a:self.Finish
    let l:info[0] = 3
    let l:info[1] = a:self.Finish
    let l:info[2] = s:ParseInputArgs(a:cmd)
    return l:info
  endif

  if a:cmd == "c"
        \ || a:cmd == "continue"
    let l:info[0] = 4
    let l:info[1] = a:self.Continue
    let l:info[2] = s:ParseInputArgs(a:cmd)
    return l:info
  endif

  if a:cmd == "r"
        \ || a:cmd == "run"
    let l:info[0] = 5
    let l:info[1] = a:self.Run
    let l:info[2] = s:ParseInputArgs(a:cmd)
    return l:info
  endif

  if a:cmd =~ "^b "
        \ || a:cmd =~ "^break "
    let l:info[0] = 6
    let l:info[1] = a:self.Break
    let l:info[2] = s:ParseInputArgs(a:cmd)
    return l:info
  endif

  return l:info
endfunction

function s:ProcessMsg(channel, text) abort
  let l:text = v:null

  if a:text =~ '(gdb)'
        \ || a:text == '^done'
        \ || (a:text[0] == '&' && a:text !~ '^&"disassemble')
    return v:null
  endif

  if a:text =~ '^\^error,msg='
    let l:text = vimext#debug#DecodeMessage(a:text[11:], v:false)
    if exists('s:evalexpr') && text =~ 'A syntax error in expression, near\|No symbol .* in current context'
      " Silently drop evaluation errors.
      unlet s:evalexpr
      return v:null
    endif
  elseif a:text[0] == '~'
    let l:text = vimext#debug#DecodeMessage(a:text[1:], v:false)
  else
    return a:text
  endif

  return l:text
endfunction

function s:MIDecodeLine(msg) abort
  let l:info = [0, 0, 0, 0, 0, 0]

  if a:msg =~ '^\*stopped,reason="breakpoint-hit"'
    let l:nameIdx = matchlist(a:msg, '^\*stopped,reason="breakpoint-hit",\S*,bkptno="\(\d\+\)",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 1
    let l:info[1] = l:nameIdx[1]  " breakpoint
    let l:info[2] = l:nameIdx[2]  " filename
    let l:info[3] = l:nameIdx[3]  " lineno
    let l:info[4] = l:nameIdx[4]  " col
    return l:info
  endif

  if a:msg =~ '^\*stopped,reason="exited",exit-code="0"'
    let l:info[0] = 2
    return l:info
  endif

  if a:msg =~ '^\^running'
    let l:info[0] = 3
    return l:info
  endif

  if a:msg =~ '^\^done,bkpt='
    call vimext#logger#Info(a:msg)
    let l:nameIdx = matchlist(a:msg, '^\^done,bkpt={number="\(\d*\)",type=\([^,]\+\),disp=\([^,]\+\),enabled="\(\w\)",warning=\([^}]*\)}')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 4         " user set breakpoint
    let l:info[1] = l:nameIdx[1]  " break number
    let l:info[2] = l:nameIdx[2]  " type
    let l:info[3] = fnameescape(expand('%:p'))   " filename
    let l:info[4] = l:nameIdx[4] == "y" ? 1 : 0  " enable
    let l:info[5] = vimext#debug#DecodeMessage(l:nameIdx[5], v:true) " warning
    return l:info
  endif


  if a:msg =~ '^\*stopped,reason="end-stepping-range"'
    let l:nameIdx = matchlist(a:msg, '^\*stopped,reason="end-stepping-range",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 5
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    return l:info
  endif


  if a:msg =~ '^=library-loaded,'
        \ || a:msg =~ '^=symbols-loaded,'
        \ || a:msg =~ '^=no-symbols-loaded,'
        \ || a:msg =~ '^=breakpoint-modified,'
        \ || a:msg =~ '^=thread'
        \ || a:msg =~ '^\^done'
    let l:info[0] = 7
    return l:info
  endif

  "=message,text="ok1\n\r\n",send-to="output-window"
  if a:msg =~ '^=message,'

    let l:nameIdx = matchlist(a:msg, '^=message,text=\([^,]*\),send-to=\([^,]*\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)
    let l:info[2] = l:nameIdx[2]

    return l:info
  endif

  if a:msg =~ '^\*stopped,reason="entry-point-hit"'
    let l:nameIdx = matchlist(a:msg, '^\*stopped,reason="entry-point-hit",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 9
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    return l:info
  endif

  return l:info
endfunction

function s:CLIDecodeLine(msg) abort
  let l:info = [0, 0, 0, 0]

  if a:msg =~ '^stopped, reason: breakpoint'
    let l:nameIdx = matchlist(a:msg, 'stopped, reason: breakpoint \(\d\+\) hit, .* frame={\S* at \([^}]*\):\(\d\+\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 1
    let l:info[1] = l:nameIdx[1]  " breakpoint
    let l:info[2] = l:nameIdx[2]  " filename
    let l:info[3] = l:nameIdx[3]  " lineno
    return l:info
  endif

  if a:msg =~ '^\^stopped, reason: exited, exit-code: 0'
    let l:info[0] = 2
    return l:info
  endif

  if a:msg =~ '^\^running'
    let l:info[0] = 3
    return l:info
  endif

  if a:msg =~ '^ Breakpoint ' " user set breakpoint
    let l:info[0] = 4
    let l:nameIdx = matchlist(a:msg, ' Breakpoint \(\d\+\)')

    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[1] = l:nameIdx[1]  " breakpoint number
    return l:info
  endif

  if a:msg =~ 'stopped, reason: end stepping range,'
    let l:info[0] = 5

    let l:nameIdx = matchlist(a:msg, 'stopped, reason: end stepping range, .* frame={\S* at \([^}]*\):\(\d\+\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[1] = l:nameIdx[1]  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    return l:info
  endif

  if a:msg =~ '^\^exit'
    let l:info[0] = 6
    return l:info
  endif

  if a:msg =~ '^library loaded:'
              \ || a:msg =~ '^symbols loaded,'
              \ || a:msg =~ '^no symbols loaded,'
              \ || a:msg =~ '^breakpoint modified,'
              \ || a:msg =~ '^thread created,'
    let l:info[0] = 7
    return l:info
  endif

  return l:info
endfunction

function s:Dispose(self) abort
endfunction
