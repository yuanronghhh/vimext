let s:self = v:null
let s:lines = []
let s:state = 0
let s:varname = "<value>"
let s:lastcmd = "next"
let s:isballoon = v:false

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
        \ "DataEvaluate": "-data-evaluate-expression",
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
    return [a:cmd, ""]
  endif

  return [nameIdx[1], nameIdx[2]]
endfunction

function vimext#proto#ParseCmds(self, argstr) abort
  let cmds = []

  if a:self.name == "mi"
    if stridx(a:argstr, "*") > -1
      :call add(cmds, [a:self.VarCreate, " _innervar" . " " . "\"" . substitute(a:argstr, "*", "", "g") . "\""])
      :call add(cmds, [a:self.VarChildren, "_innervar"])
    else
      :call add(cmds, [a:self.VarCreate, "_innervar" . "  " . "\"" . a:argstr . "\""])
      :call add(cmds, [a:self.Eval, "_innervar"])
    endif
  else
    :call add(cmds, [a:self.Print, a:argstr])
  endif
  let s:varname = a:argstr

  return cmds
endfunction

function vimext#proto#ProcessExpr(self, expr, isballoon) abort
  let s:isballoon = a:isballoon
  " lhs,rhs
  let cmds = vimext#proto#ParseCmds(a:self, a:expr)

  return cmds
endfunction

function s:ProcessInput(self, cmdstr) abort
  let cmds = []
  let vals = vimext#proto#ParseInputArgs(a:cmdstr)
  let cmd = vals[0]
  let args = vals[1]

  if vals[0] == ''
    let cmd = s:lastcmd
  else
    let s:lastcmd = cmd
  endif

  if cmd == "q"
        \ || cmd == "quit"
        \ || cmd == "exit"

    :call add(cmds, [a:self.Exit, args])

  elseif cmd == "s"
        \ || cmd == "step"

    :call add(cmds, [a:self.Step, args])

  elseif cmd == "fin"
        \ || cmd == "finish"

    :call add(cmds, [a:self.Finish, args])
  elseif cmd == "c"
        \ || cmd == "continue"

    :call add(cmds, [a:self.Continue, args])
  elseif cmd == "n"
        \ || cmd == "next"

    :call add(cmds, [a:self.Next, args])

  elseif cmd == "r"
        \ || cmd == "run"

    :call add(cmds, [a:self.Run, args])

  elseif cmd == "b"
        \ || cmd == "break"

    :call add(cmds, [a:self.Break, args])

  elseif cmd == "p"
        \ || cmd == "print"
    let expcmds = vimext#proto#ProcessExpr(a:self, args, v:false)

    :call extend(cmds, expcmds)
  else

    :call add(cmds, [cmd, args])
  endif

  return cmds
endfunction

function vimext#proto#ProcessMsg(text) abort
  if a:text =~ "(gdb)"
        \ || a:text == ""
        \ || a:text[0] == "&"
    return v:null
  endif

  return a:text
endfunction

function s:GetLine(self) abort
  return s:lines
endfunction

function s:HandleAsmInfo(info, msg) abort
  let info = a:info
  let msg = a:msg

  if s:state == 0
    if msg =~ '^\~"Dump of assembler code for function '
      let nameIdx = matchlist(msg, '^\~"Dump of assembler code for function \([^$]\+\):')

      if len(nameIdx) > 0
        let info[0] = 15
        let info[1] = nameIdx[1]
      endif

      let s:lines = []
      let s:state = 1
      return v:true
    endif

  elseif s:state == 1
    if msg =~ '^\~"End of assembler dump.'
      let info[0] = 16
      let info[1] = s:lines
      let s:state = 0

    elseif msg =~ '^\~"=>'
      let nameIdx = matchlist(msg[2:], '^=>\s\+\(\S\+\) <+\(\d\+\)>')
      let msg = vimext#debug#DecodeMessage2(msg[1:])

      if len(nameIdx) > 0
        let info[0] = 14
        let info[1] = nameIdx[1]
        let info[2] = nameIdx[2]
        let info[3] = substitute(msg, "^=>[ ]*", "", "")
        :call add(s:lines, info[3])
      endif

    elseif msg[0] == '~'
      let info[0] = 0
      let line = msg[1:]
      let line = substitute(line, '^\"[ ]*', "", "")
      let line = substitute(line, '\\n\"\r$', '', '')
      let line = substitute(line, '\\n\"$', '', '')
      let line = substitute(line, '\r', '', '')
      let line = substitute(line, '\\t', '\t', 'g')
      :call add(s:lines, line)
    else
      return v:false
    endif

    return v:true
  else
    return v:false
  endif
endfunction

function s:ParseChildrenInfo(msg) abort
  let msgs = split(a:msg, "},")

  let values = []
  for ch in msgs
    let nameIdx = matchlist(ch, 'child={name="\([^\"]*\)",attributes="\([^"]*\)",exp="\([^"]*\)",numchild="\(\d\+\)",type="\([^"]*\)",thread-id="\(\d\+\)"')

    if len(nameIdx) > 0
      :call add(values, nameIdx)
    endif
  endfor

  return values
endfunction

function s:MIProcessOutput(msg) abort
  let msg = vimext#proto#ProcessMsg(a:msg)
  if msg is v:null
    return v:null
  endif

  let info = [0, v:null, v:null, v:null, v:null, v:null, v:null, v:null, v:null, v:null]
  if g:vimext_debug == 1
    let info[9] = msg
  endif

  if s:HandleAsmInfo(info, msg)
    return info
  endif

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

  elseif msg =~ '^\^done,value='
    let nameIdx = matchlist(msg, '^\^done,value=\(.*\)')

    if len(nameIdx) > 0
      " balloon can show multiple line
      let info[0] = 3
      let info[1] = s:varname . " = " . vimext#debug#DecodeText(nameIdx[1])
    endif

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

  elseif msg[0] == '~'
    let info[0] = 8
    let info[1] = vimext#debug#DecodeMessage2(msg[1:])

  elseif msg =~ '^=message,text='
    let nameIdx = matchlist(msg, '^=message,text=\([^\n]*\),send-to="\([^,]\+"\)')

    if len(nameIdx) > 0
      let info[0] = 8
      let info[1] = vimext#debug#DecodeMessage2(nameIdx[1])
      let info[2] = nameIdx[2]
    endif

  elseif msg =~ '^\^done,bkpt=.*,warning='
    let nameIdx = matchlist(msg, '^\^done,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)",warning=\([^}]*\)}')

    if len(nameIdx) > 0
      let info[0] = 9         " user set breakpoint
      let info[1] = vimext#debug#DecodeText(nameIdx[5]) " warning
      let info[2] = nameIdx[1]  " break number
      let info[3] = nameIdx[2]  " type
      let info[4] = nameIdx[3] == "y" ? 1 : 0  " enable
    endif

  elseif msg =~ '^=cmd-param-changed,'
    let nameIdx = matchlist(msg, '^=cmd-param-changed,param="\([^\n]\+\)",value="\([^,]\+\)"')

    if len(nameIdx) > 0
      let info[0] = 8
      let info[1] = [nameIdx[1] . " " . nameIdx[2]]
    endif

  elseif msg =~ '^\^done,name='
    let nameIdx = matchlist(msg, '^\^done,name="\([^"]*\)",value=\([^,]*\),attributes="\([^"]*\)",exp="\([^"]*\)"')

    if len(nameIdx) > 0
      let info[0] = 8
      let info[1] = split(nameIdx[4] . " = " . vimext#debug#DecodeText(nameIdx[2]), "\n")
    endif

  elseif msg =~ '^\^done,numchild='
    let nameIdx = matchlist(msg, '^\^done,numchild="\(\d\+\)",children=\[\([^\n]\+\)\].*')

    if len(nameIdx) > 0
      let values = s:ParseChildrenInfo(nameIdx[2])

      let chstr = []
      :call add(chstr, "{")
      for ch in values
        :call add(chstr, "    \"" . ch[3] . "\" (" . ch[5] . ") [" . ch[4] . "]")
      endfor
      :call add(chstr, "}")

      if len(nameIdx) > 0
        let info[0] = 8
        let info[1] = chstr
      endif
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
      let info[1] = vimext#debug#DecodeMessage2(nameIdx[1])
    endif
    let s:varname = "<value>"

  elseif msg =~ '\*stopped,reason="exception-received",'
    let nameIdx = matchlist(msg, '^\*stopped,reason="exception-received",exception-name="\([^"]\+\)",exception="\([^"]\+\)",')
    if len(nameIdx) > 0
      let info[0] = 10
      let info[1] = [nameIdx[1] . ": " . vimext#debug#DecodeText('"' . nameIdx[2] . '\"')]
    endif

  elseif msg =~ '^\*stopped,reason="exited",exit-code='
    let nameIdx = matchlist(msg, '^\*stopped,reason="exited",exit-code="\(\d\+\)"')
    if len(nameIdx) > 0
      let info[0] = 10
      let info[1] = "exit-code: " . nameIdx[1]
    endif

  elseif msg =~ '^-data-evaluate-expression'
    let nameIdx = matchlist(msg, '-data-evaluate-expression "\([^"]*\)"')

    if len(nameIdx) > 0
      let info[0] = 17
      let info[1] = nameIdx[1]
      let s:varname = nameIdx[1]
    endif
  else
    return v:null
  endif

  return info
endfunction

function s:Dispose(self) abort
endfunction
