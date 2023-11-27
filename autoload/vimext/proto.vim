function vimext#proto#Create(name) abort
  let s:mi_cmd = {
        \ "name": "mi",
        \ "Break": "-break-insert",
        \ "Clear": "-break-delete",
        \ "Arguments": "-exec-arguments",
        \ "Abort": "-exec-abort",
        \ "Run": "-exec-run",
        \ "Step": "-exec-step",
        \ "Next": "-exec-next",
        \ "Finish": "-exec-finish",
        \ "Interrupt": "-exec-interrupt",
        \ "Continue": "-exec-continue",
        \ "Until": "-exec-until",
        \ "Eval": "-var-evaluate-expression",
        \ "VarCreate": "-var-create",
        \ "VarChildren": "-var-list-children",
        \ "Frame": "-interpreter-exec mi frame",
        \ "Console": "-interpreter-exec console",
        \ "Attach": "--attach",
        \ "Source": "source",
        \ "Set": "-gdb-set",
        \ "Exit": "-gdb-exit",
        \ "SaveBreakoints": "save breakpoints",
        \ "Start": "start",
        \ "Disassemble": "disassemble",
        \ "Print": "print",
        \ "ProcessOutput": function("s:MIProcessOutput"),
        \ "ProcessInput": function("s:ProcessInput"),
        \ "Dispose": function("s:Dispose"),
        \ }

  let s:vscode_cmd = {
        \ "name": "vscode",
        \ }

  let l:self = v:null
  if a:name == "mi"
    let l:self = s:mi_cmd
  endif

  if a:name == "mi2"
    let s:mi_cmd.name = "mi2"
    let l:self = s:mi_cmd
  endif

  if a:name == "vscode"
    let l:self = s:vscode_cmd
  endif

  return l:self
endfunction

function vimext#proto#GetStart(self) abort
  if a:self.name == "mi"
    return a:self.Run
  elseif a:self.name == "mi2"
    return a:self.Start
  else
    return v:null
  endif
endfunction

function vimext#proto#ParseInputArgs(cmd) abort
  let l:nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(l:nameIdx) <= 2
    return ""
  endif

  return l:nameIdx[2]
endfunction

function s:ProcessInput(self, cmd) abort
  " type,cmd,args,pre-execute-cmd
  let l:info = [0, "", "", 0]
  let l:cmd = "next"

  if a:cmd != "" && a:cmd isnot v:null
    let l:cmd = a:cmd
    let l:info[1] = l:cmd
  endif

  if l:cmd == "q"
        \ || l:cmd == "quit"
        \ || l:cmd == "exit"
    let l:info[0] = 1
    let l:info[1] = a:self.Exit
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)
    return l:info
  endif

  if l:cmd == "s"
        \ || l:cmd == "step"
    let l:info[0] = 2
    let l:info[1] = a:self.Step
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)
    return l:info
  endif

  if l:cmd == "fin"
        \ || l:cmd == "finish"
    let l:info[0] = 3
    let l:info[1] = a:self.Finish
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)
    return l:info
  endif

  if l:cmd == "c"
        \ || l:cmd == "continue"
    let l:info[0] = 4
    let l:info[1] = a:self.Continue
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)
    return l:info
  endif

  if l:cmd == "n"
        \ || l:cmd == "next"
    let l:info[0] = 4
    let l:info[1] = a:self.Next
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)
    return l:info
  endif

  if l:cmd == "r"
        \ || l:cmd == "run"
    let l:info[0] = 5
    let l:info[1] = a:self.Run
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)
    return l:info
  endif

  if l:cmd =~ "^b "
        \ || l:cmd =~ "^break "
    let l:info[0] = 6
    let l:info[1] = a:self.Break
    let l:info[2] = vimext#proto#ParseInputArgs(l:cmd)

    return l:info
  endif

  if l:cmd =~ "^p "
        \ || l:cmd =~ "^print "
    let l:args = vimext#proto#ParseInputArgs(l:cmd)

    if a:self.name == "mi"
      if stridx(l:args, "*") > -1
        let l:info[1] = a:self.VarChildren
        let l:info[2] = "_innervar"
        let l:info[3] = a:self.VarCreate . " _innervar" . "  " . "\"" . substitute(l:args, "*", "", "g") . "\""
      else
        let l:info[1] = a:self.VarCreate
        let l:info[2] = "_innervar" . "  " . "\"" . l:args . "\""
      endif
    else
      let l:info[1] = a:self.Print
      let l:info[2] = l:args
    endif

    let l:info[0] = 7
    return l:info
  endif

  return l:info
endfunction

function vimext#proto#ProcessMsg(text) abort
  let l:text = v:null

  if a:text =~ '(gdb)' || a:text[0] == '&' || a:text == ""
    return v:null
  endif

  if a:text[0] == '~'
    let l:text = vimext#debug#DecodeMessage(a:text[1:], v:false)
  else
    return a:text
  endif

  return l:text
endfunction

function s:MIProcessOutput(msg) abort
  let l:msg = vimext#proto#ProcessMsg(a:msg)
  if l:msg is v:null || l:msg == ""
    return
  endif

  let l:info = [7, 0, 0, 0, 0, 0, 0, 0, 0, l:msg]

  if l:msg =~ '^\*stopped,reason="breakpoint-hit"'
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="breakpoint-hit",\S*,bkptno="\(\d*\)",\S*,fullname=\([^,]*\),line="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 1
    let l:info[1] = l:nameIdx[1]  " breakpoint
    let l:info[2] = vimext#debug#DecodeFilePath(l:nameIdx[2])  " filename
    let l:info[3] = l:nameIdx[3]  " lineno
    let l:info[4] = l:nameIdx[4]  " col -> this only for netcoredbg

  elseif l:msg == '*stopped,reason="exited",exit-code="0"'
        \ || l:msg == '*stopped,reason="exited-normally"'
    let l:info[0] = 2
  elseif l:msg == '^running'
    let l:info[0] = 3
  elseif l:msg =~ '^=breakpoint-created,bkpt'
        \ || l:msg =~ '^=breakpoint-modified,bkpt'
        \ || l:msg =~ '^\^done,bkpt=\S*,fullname='
    let l:nameIdx = matchlist(l:msg, '^[^,]\+,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)"\S*,func="\([^,]*\)",file="\([^,]*\)",fullname=\([^,]*\),line="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 4         " user set breakpoint
    let l:info[1] = l:nameIdx[1]  " break number
    let l:info[2] = l:nameIdx[2]  " type
    let l:info[3] = l:nameIdx[3]  " disp
    let l:info[4] = l:nameIdx[4] ? "y" : 0  " enable
    let l:info[5] = l:nameIdx[5]  " func
    let l:info[6] = l:nameIdx[6]  " file
    let l:info[7] = vimext#debug#DecodeFilePath(l:nameIdx[7]) " fullname
    let l:info[8] = l:nameIdx[8] " line
  elseif l:msg =~ '^\*stopped,reason="end-stepping-range"'
        \ || l:msg =~ '^\*stopped,reason="function-finished"'
        \ || l:msg =~ '\*stopped,reason="signal-received"'

    ""*stopped,reason="end-stepping-range",frame={addr="0x00007ff8c315a890",func="ntdll!RtlEnterCriticalSection",args=[],from="C:\\Windows\\SYSTEM32\\ntdll.dll",arch="i386:x86-64"},thread-id="1",stopped-threads="all"
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason=.*,fullname=\([^,]*\),line="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 5
    let l:info[1] = vimext#debug#DecodeFilePath(l:nameIdx[1])  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col -> only for netcoredbg

  elseif l:msg =~ '^=thread-selected,'
    let l:nameIdx = matchlist(l:msg, '^=thread-selected,.*,fullname=\([^,]\+\),line="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 5
    let l:info[1] = vimext#debug#DecodeFilePath(l:nameIdx[1])  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col -> only for netcoredbg

  elseif l:msg =~ '^\^exit'
    let l:info[0] = 6

  elseif l:msg =~ '^\^done,bkpt=\S*,warning='
    let l:nameIdx = matchlist(l:msg, '^\^done,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)",warning=\([^}]*\)}')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8         " user set breakpoint
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[5], v:true) " warning
    let l:info[2] = l:nameIdx[1]  " break number
    let l:info[3] = l:nameIdx[2]  " type
    let l:info[4] = l:nameIdx[3] == "y" ? 1 : 0  " enable
  elseif l:msg =~ '^=message,text='
    let l:nameIdx = matchlist(l:msg, '^=message,text=\([^\n]*\),send-to="\([^,]\+"\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:false)
    let l:info[2] = l:nameIdx[2]
  elseif l:msg =~ '^=cmd-param-changed,'
    let l:nameIdx = matchlist(l:msg, '^=cmd-param-changed,param="\([^\n]\+\)",value="\([^,]\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = l:nameIdx[1] . " " . l:nameIdx[2]

  elseif l:msg =~ '^\^done,name='
    call vimext#logger#Info("ok")
    let l:nameIdx = matchlist(l:msg, '^\^done,name="\([^"]*\)",value=\([^,]*\),attributes="\([^"]*\)",exp="\([^"]*\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = l:nameIdx[4] . " = " . vimext#debug#DecodeMessage(l:nameIdx[2], v:false)

  elseif l:msg =~ '^\*stopped,reason="entry-point-hit"'
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="entry-point-hit",.*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 9
    let l:info[1] = vimext#debug#DecodeFilePath(l:nameIdx[1])  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    let l:info[4] = 0  " breakid
  elseif l:msg =~ '^\^error,msg='
    let l:nameIdx = matchlist(l:msg, '^\^error,msg=\([^$]\+\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 10
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:false)

  elseif l:msg =~ '\*stopped,reason="exception-received",'
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="exception-received",exception-name="\([^"]\+\)",exception="\([^"]\+\)",')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 10
    let l:info[1] = l:nameIdx[1] . ": " . vimext#debug#DecodeMessage('"' . l:nameIdx[2] . '\"', v:false)

  elseif l:msg =~ '^\*stopped,reason="exited",exit-code='
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="exited",exit-code="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 10
    let l:info[1] = "exit-code: " . l:nameIdx[1]

  elseif l:msg =~ '^=breakpoint-deleted,id='
    let l:nameIdx = matchlist(l:msg, '=breakpoint-deleted,id="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 11
    let l:info[1] = l:nameIdx[1] " breakpoint id

  elseif l:msg =~ '^=>'
    let l:nameIdx = matchlist(l:msg, '^=>\s\+\(\S\+\) <+\(\d\+\)>')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 14
    let l:info[1] = l:nameIdx[1]
    let l:info[2] = l:nameIdx[2]
    let l:info[3] = substitute(l:info[9], "^=>[ ]*", "", "")

  elseif l:msg =~ 'Dump of assembler code for function '
    let l:nameIdx = matchlist(l:msg, '^Dump of assembler code for function \([^$]\+\):')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 15
    let l:info[1] = l:nameIdx[1]

  elseif l:msg == 'End of assembler dump.'
    let l:info[0] = 16

  elseif l:msg =~ '^='
        \ || l:msg == '^done'
        \ || l:msg =~ '^*running,thread-id'
    " ignored
    "
    let l:info[0] = 7
  else

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
