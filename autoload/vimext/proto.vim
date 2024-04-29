let s:self = v:null


function vimext#proto#Create(name) abort
  let s:mi_cmd = {
        \ "name": "mi",
        \ "state": 0,
        \ "lines": [],
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

  let self = v:null
  if a:name == "mi"
    let self = s:mi_cmd
  endif

  if a:name == "mi2"
    let s:mi_cmd.name = "mi2"
    let self = s:mi_cmd
  endif

  if a:name == "vscode"
    let self = s:vscode_cmd
  endif

  let s:self = self

  return self
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
  let nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(nameIdx) <= 2
    return ""
  endif

  return nameIdx[2]
endfunction

function s:ProcessInput(self, cmd) abort
  " type,cmd,args,pre-execute-cmd
  let info = [0, "", "", 0]
  let cmd = "next"

  if a:cmd != "" && a:cmd isnot v:null
    let cmd = a:cmd
    let info[1] = cmd
  endif

  if cmd == "q"
        \ || cmd == "quit"
        \ || cmd == "exit"
    let info[0] = 1
    let info[1] = a:self.Exit
    let info[2] = vimext#proto#ParseInputArgs(cmd)
    return info
  endif

  if cmd == "s"
        \ || cmd == "step"
    let info[0] = 2
    let info[1] = a:self.Step
    let info[2] = vimext#proto#ParseInputArgs(cmd)
    return info
  endif

  if cmd == "fin"
        \ || cmd == "finish"
    let info[0] = 3
    let info[1] = a:self.Finish
    let info[2] = vimext#proto#ParseInputArgs(cmd)
    return info
  endif

  if cmd == "c"
        \ || cmd == "continue"
    let info[0] = 4
    let info[1] = a:self.Continue
    let info[2] = vimext#proto#ParseInputArgs(cmd)
    return info
  endif

  if cmd == "n"
        \ || cmd == "next"
    let info[0] = 4
    let info[1] = a:self.Next
    let info[2] = vimext#proto#ParseInputArgs(cmd)
    return info
  endif

  if cmd == "r"
        \ || cmd == "run"
    let info[0] = 5
    let info[1] = a:self.Run
    let info[2] = vimext#proto#ParseInputArgs(cmd)
    return info
  endif

  if cmd =~ "^b "
        \ || cmd =~ "^break "
    let info[0] = 6
    let info[1] = a:self.Break
    let info[2] = vimext#proto#ParseInputArgs(cmd)

    return info
  endif

  if cmd =~ "^p "
        \ || cmd =~ "^print "
    let args = vimext#proto#ParseInputArgs(cmd)

    if a:self.name == "mi"
      if stridx(args, "*") > -1
        let info[1] = a:self.VarChildren
        let info[2] = "_innervar"
        let info[3] = a:self.VarCreate . " _innervar" . "  " . "\"" . substitute(args, "*", "", "g") . "\""
      else
        let info[1] = a:self.VarCreate
        let info[2] = "_innervar" . "  " . "\"" . args . "\""
      endif
    else
      let info[1] = a:self.Print
      let info[2] = args
    endif

    let info[0] = 7
    return info
  endif

  return info
endfunction

function vimext#proto#ProcessMsg(text) abort
  let text = v:null

  if a:text =~ "(gdb)"
        \ || a:text == ""
        \ || a:text[0] == "&"
    return v:null
  endif

  return a:text
endfunction

function s:GetLine(self) abort
  return a:self.lines
endfunction

function s:MIProcessOutput(msg) abort
  let msg = vimext#proto#ProcessMsg(a:msg)
  if msg is v:null
    return v:null
  endif

  let info = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  if msg =~ '^\*stopped,reason="breakpoint-hit"'
    let nameIdx = matchlist(msg, '^\*stopped,reason="breakpoint-hit",.*,bkptno="\(\d*\)",.*,fullname=\([^,]*\),line="\(\d\+\)"')
    if len(nameIdx) == 0
      return info
    endif

    let info[0] = 1
    let info[1] = nameIdx[1]  " breakpoint
    let info[2] = vimext#debug#DecodeFilePath(nameIdx[2])  " filename
    let info[3] = nameIdx[3]  " lineno
    let info[4] = nameIdx[4]  " col -> this only for netcoredbg

  elseif msg == '*stopped,reason="exited",exit-code="0"'
        \ || msg == '*stopped,reason="exited-normally"'
    let info[0] = 2

  elseif msg =~ '^=breakpoint-deleted,id='
    let nameIdx = matchlist(msg, '=breakpoint-deleted,id="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 11
      let info[1] = nameIdx[1] " breakpoint id
    endif

  elseif msg =~ '^=breakpoint-created,bkpt'
        \ || msg =~ '^=breakpoint-modified,bkpt'
        \ || msg =~ '^\^done,bkpt=.*,fullname='

    let nameIdx = matchlist(msg, '^[^,]\+,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)".*,func="\([^,]*\)",file="\([^,]*\)",fullname=\([^,]*\),line="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 4         " user set breakpoint
      let info[1] = nameIdx[1]  " break number
      let info[2] = nameIdx[2]  " type
      let info[3] = nameIdx[3]  " disp
      let info[4] = nameIdx[4] ? "y" : 0  " enable
      let info[5] = nameIdx[5]  " func
      let info[6] = nameIdx[6]  " file
      let info[7] = vimext#debug#DecodeFilePath(nameIdx[7]) " fullname
      let info[8] = nameIdx[8] " line
    else
      let info[0] = 7
    endif

  elseif msg =~ '^\*stopped,reason="end-stepping-range"'
        \ || msg =~ '^\*stopped,reason="function-finished"'
        \ || msg =~ '\*stopped,reason="signal-received"'

    let nameIdx = matchlist(msg, '^\*stopped,reason=.*,fullname=\([^,]*\),line="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 5
      let info[1] = vimext#debug#DecodeFilePath(nameIdx[1])  " filename
      let info[2] = nameIdx[2]  " lineno
      let info[3] = nameIdx[3]  " col -> only for netcoredbg
    endif

  elseif msg =~ '^=thread-selected,'
    let nameIdx = matchlist(msg, '^=thread-selected,.*,fullname=\([^,]\+\),line="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 5
      let info[1] = vimext#debug#DecodeFilePath(nameIdx[1])  " filename
      let info[2] = nameIdx[2]  " lineno
      let info[3] = nameIdx[3]  " col -> only for netcoredbg
    endif
  elseif msg =~ '^\^exit'
    let info[0] = 6

  elseif msg =~ '^=message,text='
    let nameIdx = matchlist(msg, '^=message,text=\([^\n]*\),send-to="\([^,]\+"\)')

    if len(nameIdx) > 0
      let info[0] = 8
      let info[1] = vimext#debug#DecodeMessage(nameIdx[1], v:false)
      let info[2] = nameIdx[2]
    endif

  elseif msg =~ '^\^done,bkpt=.*,warning='
    let nameIdx = matchlist(msg, '^\^done,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)",warning=\([^}]*\)}')

    if len(nameIdx) > 0
      let info[0] = 9         " user set breakpoint
      let info[1] = vimext#debug#DecodeMessage(nameIdx[5], v:true) " warning
      let info[2] = nameIdx[1]  " break number
      let info[3] = nameIdx[2]  " type
      let info[4] = nameIdx[3] == "y" ? 1 : 0  " enable
    endif

  elseif msg =~ '^\~"Dump of assembler code for function '
    let nameIdx = matchlist(msg, '^\~"Dump of assembler code for function \([^$]\+\):')

    if len(nameIdx) > 0
      let info[0] = 15
      let info[1] = nameIdx[1]
    endif

    let s:self.state = 1
    let s:self.lines = []
  elseif msg =~ '^\~"End of assembler dump.'
    let info[0] = 16
    let info[1] = s:self.lines
    let s:self.state = 0

  elseif msg =~ '^\~"=>'
    let nameIdx = matchlist(msg[2:], '^=>\s\+\(\S\+\) <+\(\d\+\)>')
    let msg = vimext#debug#DecodeMessage(msg[1:], v:false)

    if len(nameIdx) > 0
      let info[0] = 14
      let info[1] = nameIdx[1]
      let info[2] = nameIdx[2]
      let info[3] = substitute(msg, "^=>[ ]*", "", "")
      :call add(s:self.lines, info[3])
    endif
  elseif msg[0] == '~'

    if s:self.state == 1
      let info[0] = 0
      let line = vimext#debug#DecodeMessage(msg[1:], v:false)
      let line = substitute(line, '^[ ]*', "", "g")
      let line = substitute(line, '^=>[ ]*', "", "g")
      :call add(s:self.lines, line)
    else
      let info[0] = 8
      let info[1] = vimext#debug#DecodeMessage(msg[1:], v:false)
    endif

  elseif msg =~ '^=cmd-param-changed,'
    let nameIdx = matchlist(msg, '^=cmd-param-changed,param="\([^\n]\+\)",value="\([^,]\+\)"')

    if len(nameIdx) > 0
      let info[0] = 8
      let info[1] = nameIdx[1] . " " . nameIdx[2]
    endif

  elseif msg =~ '^\^done,name='
    let nameIdx = matchlist(msg, '^\^done,name="\([^"]*\)",value=\([^,]*\),attributes="\([^"]*\)",exp="\([^"]*\)"')

    if len(nameIdx) > 0
      let info[0] = 8
      let info[1] = nameIdx[4] . " = " . vimext#debug#DecodeMessage(nameIdx[2], v:false)
    endif

  elseif msg =~ '^\*stopped,reason="entry-point-hit"'
    let nameIdx = matchlist(msg, '^\*stopped,reason="entry-point-hit",.*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 9
      let info[1] = vimext#debug#DecodeFilePath(nameIdx[1])  " filename
      let info[2] = nameIdx[2]  " lineno
      let info[3] = nameIdx[3]  " col
      let info[4] = 0  " breakid
    endif

  elseif msg =~ '^\^error,msg='
    let nameIdx = matchlist(msg, '^\^error,msg=\([^$]\+\)')

    if len(nameIdx) > 0
      let info[0] = 10
      let info[1] = vimext#debug#DecodeMessage(nameIdx[1], v:false)
    endif

  elseif msg =~ '\*stopped,reason="exception-received",'
    let nameIdx = matchlist(msg, '^\*stopped,reason="exception-received",exception-name="\([^"]\+\)",exception="\([^"]\+\)",')
    if len(nameIdx) > 0
      let info[0] = 10
      let info[1] = nameIdx[1] . ": " . vimext#debug#DecodeMessage('"' . nameIdx[2] . '\"', v:false)
    endif

  elseif msg =~ '^\*stopped,reason="exited",exit-code='
    let nameIdx = matchlist(msg, '^\*stopped,reason="exited",exit-code="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 10
      let info[1] = "exit-code: " . nameIdx[1]
    endif
  else
    return v:null
  endif

  return info
endfunction

function s:Dispose(self) abort
endfunction
