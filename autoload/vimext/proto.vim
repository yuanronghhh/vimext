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
        \ "Source": "source",
        \ "Set": "-gdb-set",
        \ "Exit": "-gdb-exit",
        \ "SaveBreakoints": "save breakpoints",
        \ "ProcessOutput": function("s:MIProcessOutput"),
        \ "ProcessInput": function("s:ProcessInput"),
        \ "ProcessMsg": function("s:ProcessMsg"),
        \ "Dispose": function("s:Dispose")
        \ }

  let s:vscode_cmd = {
        \ "name": "vscode",
        \ "Dispose": function("s:Dispose")
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

function vimext#proto#ParseInputArgs(cmd)
  let l:nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(l:nameIdx) <= 2
    return ""
  endif

  return l:nameIdx[2]
endfunction

function s:ProcessInput(self, cmd)
  let l:info = [0, 0, 0, 0]
  " type,cmd,args,pre-execute-cmd

  let l:cmd = "next"

  if a:cmd != "" && a:cmd != v:null
    let l:cmd = a:cmd
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
    return a:self.Finish
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
        \ || l:cmd =~ "^p "
    let l:args = vimext#proto#ParseInputArgs(l:cmd)

    if stridx(l:args, "*") > -1
      let l:info[1] = a:self.VarChildren
      let l:info[2] = "_innervar"
      let l:info[3] = a:self.VarCreate . " _innervar" . "  " . "\"" . substitute(l:args, "*", "", "g") . "\""
    else
      let l:info[1] = a:self.VarCreate
      let l:info[2] = "_innervar" . "  " . "\"" . l:args . "\""
    endif

    let l:info[0] = 7
    return l:info
  endif

  return l:info
endfunction

function s:ProcessMsg(text) abort
  let l:text = v:null

  if a:text =~ '(gdb)'
        \ || a:text == '^done'
        \ || (a:text[0] == '&' && a:text !~ '^&"disassemble')
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
  let l:msg = s:ProcessMsg(a:msg)
  if l:msg == v:null
    return
  endif

  let l:info = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  if l:msg =~ '^\*stopped,reason="breakpoint-hit"'
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="breakpoint-hit",\S*,bkptno="\(\d\+\)",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 1
    let l:info[1] = l:nameIdx[1]  " breakpoint
    let l:info[2] = vimext#debug#DecodeMessage(l:nameIdx[2], v:false)  " filename
    let l:info[3] = l:nameIdx[3]  " lineno
    let l:info[4] = l:nameIdx[4]  " col
    return l:info
  endif

  if l:msg =~ '^\*stopped,reason="exited",exit-code="0"'
    let l:info[0] = 2
    return l:info
  endif

  if l:msg =~ '^\^running'
    let l:info[0] = 3
    return l:info
  endif

  if l:msg =~ '^\^done,bkpt=\S*,fullname='
    let l:nameIdx = matchlist(l:msg, '^\^done,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)",func="\([^,]*\)",file="\([^,]\+\)",fullname=\([^,]\+\),line="\(\d\+\)"')
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
    let l:info[7] = vimext#debug#DecodeMessage(l:nameIdx[7], v:true) " fullname
    let l:info[8] = l:nameIdx[8] " line
    return l:info
  endif

  if l:msg =~ '^\*stopped,reason="end-stepping-range"'
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="end-stepping-range",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 5
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    return l:info
  endif

  if l:msg =~ '^=library-loaded,'
        \ || l:msg =~ '^=symbols-loaded,'
        \ || l:msg =~ '^=no-symbols-loaded,'
        \ || l:msg =~ '^=breakpoint-modified,'
        \ || l:msg =~ '^=thread'
    let l:info[0] = 7
    return l:info
  endif

  if l:msg =~ '^\^done,bkpt=\S*,warning='
    let l:nameIdx = matchlist(l:msg, '^\^done,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)",warning=\([^}]*\)}')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8         " user set breakpoint
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[5], v:true) " warning
    let l:info[2] = l:nameIdx[1]  " break number
    let l:info[3] = l:nameIdx[2]  " type
    let l:info[4] = l:nameIdx[3] == "y" ? 1 : 0  " enable
    return l:info
  endif

  if l:msg =~ '^=message,'
    let l:nameIdx = matchlist(l:msg, '^=message,text=\([^,]*\),send-to="\([^,]\+"\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:false)
    let l:info[2] = l:nameIdx[2]

    return l:info
  endif

  if l:msg =~ '^\*stopped,reason="entry-point-hit"'
    let l:nameIdx = matchlist(l:msg, '^\*stopped,reason="entry-point-hit",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 9
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)  " filename
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    return l:info
  endif

  "^done,name="_innervar",value="\"cmd.exe\"",attributes="editable",exp="p.StartInfo.FileName",numchild="0",type="string",thread-id="20440"
  if l:msg =~ '^\^done,name='
    let l:nameIdx = matchlist(l:msg, '^\^done,name="\([^"]*\)",value=\([^,]*\),attributes="\([^"]*\)",exp="\([^"]*\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = l:nameIdx[4] . " = " . vimext#debug#DecodeMessage(l:nameIdx[2], v:false)

    return l:info
  endif

  if l:msg =~ '^\^error,msg='
    let l:nameIdx = matchlist(l:msg, '^\^error,msg=\([^$]\+\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 10
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:false)

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
