let s:self = v:null
let s:lines = []
let s:state = 0
let s:varname = "<value>"
let s:lastcmd = "next"
let s:isballoon = v:false

function vimext#proto#Create(name) abort
  let self = v:null
  if a:name == "mi" || a:name == "mi2"
    let self = vimext#proto#MiCreate()
    let self.name = a:name
  endif

  if a:name == "vscode"
    let self = vimext#proto#DapCreate()
  endif

  let s:self = self

  return self
endfunction

" mi protocol ===============
function vimext#proto#MiCreate() abort
  let self = {
        \ "name": "mi",
        \ "Break": function("s:MiBreak"),
        \ "Clear": function("s:MiClear"),
        \ "Arguments": function("s:MiArguments"),
        \ "Abort": function("s:MiAbort"),
        \ "Run": function("s:MiRun"),
        \ "Step": function("s:MiStep"),
        \ "Next": function("s:MiNext"),
        \ "Finish": function("s:MiFinish"),
        \ "Interrupt": function("s:MiInterrupt"),
        \ "Continue": function("s:MiContinue"),
        \ "Until": function("s:MiUntil"),
        \ "Eval": function("s:MiEval"),
        \ "DataEvaluate": function("s:MiDataEvaluate"),
        \ "VarCreate": function("s:MiVarCreate"),
        \ "VarChildren": function("s:MiVarChildren"),
        \ "Frame": function("s:MiFrame"),
        \ "Console": function("s:MiConsole"),
        \ "Attach": function("s:MiAttach"),
        \ "Source": function("s:MiSource"),
        \ "Set": function("s:MiSet"),
        \ "Exit": function("s:MiExit"),
        \ "SaveBreakoints": function("s:MiSaveBreakoints"),
        \ "Start": function("s:MiStart"),
        \ "Disassemble": function("s:MiDisassemble"),
        \ "Print": function("s:MiPrint"),
        \ "ProcessOutput": function("s:MiProcessOutput"),
        \ "ProcessInput": function("s:MiProcessInput"),
        \ "Call": function("s:MiCall"),
        \ "ExprToCmds": function("s:MiExprToCmds"),
        \ "Dispose": function("s:MiDispose"),
        \ }

  return self
endfunction

function vimext#proto#ParseInputArgs(cmd) abort
  let nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(nameIdx) <= 2
    return [a:cmd, ""]
  endif

  return [nameIdx[1], nameIdx[2]]
endfunction

function s:MiExprToCmds(self, expr, isballoon) abort
  let s:isballoon = a:isballoon
  " lhs,rhs
  let cmds = s:ExprToCmdsInner(a:self, a:expr)

  return cmds
endfunction

function s:MiCall(self, args) abort
  return a:args
endfunction

function s:MiDispose(self) abort
endfunction

function s:MiProcessInput(self, cmdstr) abort
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
    let expcmds = s:MiExprToCmds(a:self, args, v:false)

    :call extend(cmds, expcmds)
  else

    :call add(cmds, [a:self.Call, cmd])
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
      let msg = vimext#debug#DecodeText(msg[1:])

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

function s:MiProcessOutput(msg) abort
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
      :call vimext#logger#Info(nameIdx)
    endif
  else
    return v:null
  endif

  return info
endfunction

function s:ExprToCmdsInner(self, argstr) abort
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

function s:MiBreak(self, args) abort 
  return "-break-insert " . a:args
endfunction

function s:MiClear(self, args) abort 
  return "-break-delete " . a:args
endfunction

function s:MiArguments(self, args) abort 
  return "-exec-arguments " . a:args
endfunction

function s:MiAbort(self, args) abort 
  return "-exec-abort"
endfunction

function s:MiRun(self, args) abort 
  return "-exec-run " . a:args
endfunction

function s:MiStep(self, args) abort 
  return "-exec-step"
endfunction

function s:MiNext(self, args) abort 
  return "-exec-next"
endfunction

function s:MiFinish(self, args) abort 
  return "-exec-finish"
endfunction

function s:MiInterrupt(self, args) abort 
  return "-exec-interrupt"
endfunction

function s:MiContinue(self, args) abort 
  return "-exec-continue"
endfunction

function s:MiUntil(self, args) abort 
  return "-exec-until"
endfunction

function s:MiEval(self, args) abort 
  return "-var-evaluate-expression " . a:args
endfunction

function s:MiDataEvaluate(self, args) abort 
  return "-data-evaluate-expression " . a:args
endfunction

function s:MiVarCreate(self, args) abort 
  return "-var-create " . a:args
endfunction

function s:MiVarChildren(self, args) abort 
  return "-var-list-children " . a:args
endfunction

function s:MiFrame(self, args) abort 
  return "-interpreter-exec mi frame"
endfunction

function s:MiConsole(self, args) abort 
  return "-interpreter-exec console"
endfunction

function s:MiAttach(self, args) abort 
  return "--attach " . a:args
endfunction

function s:MiSource(self, args) abort 
  return "source " . a:args
endfunction

function s:MiSet(self, args) abort 
  return "-gdb-set " . a:args
endfunction

function s:MiExit(self, args) abort 
  return "-gdb-exit"
endfunction

function s:MiSaveBreakoints(self, args) abort 
  return "save breakpoints " . a:args
endfunction

function s:MiStart(self, args) abort
  if a:self.name == "mi"
    return s:MiRun(a:self, a:args)
  elseif a:self.name == "mi2"
    return "start"
  else
    return v:null
  endif
endfunction

function s:MiDisassemble(self, args) abort 
  return "disassemble " . a:args
endfunction

function s:MiPrint(self, args) abort 
  return "print " . a:args
endfunction

" dap protocol start
function vimext#proto#DapCreate(name) abort
  " todo implement
  let self = {
        \ "name": "dap",
        \ "Break": function("s:DapBreak"),
        \ "Clear": function("s:DapClear"),
        \ "Arguments": function("s:DapArguments"),
        \ "Abort": function("s:DapAbort"),
        \ "Run": function("s:DapRun"),
        \ "Step": function("s:DapStep"),
        \ "Next": function("s:DapNext"),
        \ "Finish": function("s:DapFinish"),
        \ "Interrupt": function("s:DapInterrupt"),
        \ "Continue": function("s:DapContinue"),
        \ "Until": function("s:DapUntil"),
        \ "Eval": function("s:DapEval"),
        \ "DataEvaluate": function("s:DapDataEvaluate"),
        \ "VarCreate": function("s:DapVarCreate"),
        \ "VarChildren": function("s:DapVarChildren"),
        \ "Frame": function("s:DapFrame"),
        \ "Console": function("s:DapConsole"),
        \ "Attach": function("s:DapAttach"),
        \ "Source": function("s:DapSource"),
        \ "Set": function("s:DapSet"),
        \ "Exit": function("s:DapExit"),
        \ "SaveBreakoints": function("s:DapSaveBreakoints"),
        \ "Start": function("s:DapStart"),
        \ "Call": function("s:DapCall"),
        \ "Disassemble": function("s:DapDisassemble"),
        \ "Print": function("s:DapPrint"),
        \ "ProcessOutput": function("s:DapProcessOutput"),
        \ "ProcessInput": function("s:DapProcessInput"),
        \ "Dispose": function("s:DapDispose"),
        \ }

  return self
endfunction
