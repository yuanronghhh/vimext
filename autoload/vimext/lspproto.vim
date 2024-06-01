let s:self = v:null
let s:state = 0
let s:lastcmd = "next"
let s:tasks = {}
let s:seq = 0

" lsp protocol start
function vimext#lspproto#Create() abort
  " todo implement
  let self = {
        \ "name": "lsp",
        \ "Initialize": function("s:LspInitialize"),
        \ "Break": function("s:LspBreak"),
        \ "Clear": function("s:LspClear"),
        \ "Arguments": function("s:LspArguments"),
        \ "Abort": function("s:LspAbort"),
        \ "Run": function("s:LspRun"),
        \ "Step": function("s:LspStep"),
        \ "Next": function("s:LspNext"),
        \ "Finish": function("s:LspFinish"),
        \ "Interrupt": function("s:LspInterrupt"),
        \ "Continue": function("s:LspContinue"),
        \ "Until": function("s:LspUntil"),
        \ "Eval": function("s:LspEval"),
        \ "DataEvaluate": function("s:LspDataEvaluate"),
        \ "VarCreate": function("s:LspVarCreate"),
        \ "VarChildren": function("s:LspVarChildren"),
        \ "Frame": function("s:LspFrame"),
        \ "Console": function("s:LspConsole"),
        \ "Attach": function("s:LspAttach"),
        \ "Source": function("s:LspSource"),
        \ "Set": function("s:LspSet"),
        \ "Exit": function("s:LspExit"),
        \ "SaveBreakoints": function("s:LspSaveBreakoints"),
        \ "Start": function("s:LspStart"),
        \ "Call": function("s:LspCall"),
        \ "Disassemble": function("s:LspDisassemble"),
        \ "Print": function("s:LspPrint"),
        \ "ProcessOutput": function("s:LspProcessOutput"),
        \ "ProcessInput": function("s:LspProcessInput"),
        \ "Dispose": function("s:LspDispose"),
        \ }

  return self
endfunction

function s:LspInitialize(self, args) abort
  let req = {}
  let req.command = 'initialize'
  let req.type = "request"
  let req.arguments = {}
  let req.arguments.linesStartAt1 =  v:true
  let req.arguments.columnsStartAt1 =  v:true
  let req.arguments.locale =  'en_GB'
  let req.arguments.pathFormat =  'path'
  let req.arguments.supportsVariableType =  v:true
  let req.arguments.supportsVariablePaging =  v:false
  let req.arguments.supportsRunInTerminalRequest =  v:true
  let req.arguments.supportsMemoryReferences =  v:true
  let req.arguments.supportsStartDebuggingRequest =  v:true

  return req
endfunction

function s:LspBefore(dic) abort
  let s:seq += 1
  let a:dic.seq = s:seq
  let a:dic.id = s:seq
  let s:tasks[s:seq] = a:dic

  return a:dic
endfunction

function s:GenBreak(mode, name, linenum) abort
  "1. fullpath,linenum
  "2. funcname
  let req = {}
  let req.type = "request"
  let req.arguments = {}
  let req.arguments.source = {}

  let req.arguments.breakpoints = []
  let brk = {
        \ "state": "ENABLED",
        \ "options": {
        \   "condition": v:null,
        \   'hitCondition': v:null
        \ }
        \ }

  if a:mode == 1
    let req.command = "setBreakpoints"
    let req.arguments.source.name = fnamemodify(a:name, "%:t")
    let req.arguments.source.path = a:name
    let brk.line = a:linenum
  elseif a:mode == 2
    let req.command = "setFunctionBreakpoints"
    let brk.name = a:name
  endif

  call add(req.arguments.breakpoints, brk)
  let req.arguments.sourceModified = v:false

  return req
endfunction

function s:LspBreak(self, args) abort
  let dic = v:null
  let args = split(a:args, " ")

  if len(args) == 2
    let dic = s:GenBreak(1, args[0], args[1])
  elseif len(args) == 1
    let dic = s:GenBreak(2, args[0], v:null)
  else
  endif

  let dic = s:LspBefore(dic)
  return dic
endfunction

function s:LspClear(self, args) abort
endfunction

function s:LspArguments(self, args) abort
endfunction

function s:LspAbort(self, args) abort
endfunction

function s:LspRun(self, args) abort
endfunction

function s:LspStep(self, args) abort
endfunction

function s:LspNext(self, args) abort
endfunction

function s:LspFinish(self, args) abort
endfunction

function s:LspInterrupt(self, args) abort
endfunction

function s:LspContinue(self, args) abort
endfunction

function s:LspUntil(self, args) abort
endfunction

function s:LspEval(self, args) abort
endfunction

function s:LspDataEvaluate(self, args) abort
endfunction

function s:LspVarCreate(self, args) abort
endfunction

function s:LspVarChildren(self, args) abort
endfunction

function s:LspFrame(self, args) abort
endfunction

function s:LspConsole(self, args) abort
endfunction

function s:LspAttach(self, args) abort
endfunction

function s:LspSource(self, args) abort
endfunction

function s:LspSet(self, args) abort
  return v:null
endfunction

function s:LspExit(self, args) abort
endfunction

function s:LspSaveBreakoints(self, args) abort
endfunction

function s:LspStart(self, args) abort
endfunction

function s:LspCall(self, args) abort
  return a:args
endfunction

function s:LspDisassemble(self, args) abort
endfunction

function s:LspPrint(self, args) abort
endfunction

function s:LspProcessOutput(self, msg) abort
  let info = [0, v:null, v:null, v:null, v:null, v:null, v:null, v:null, v:null, v:null]
  if !a:msg.success
    let info[0] = 10
    let info[1] = a:msg.message
    return info
  endif

  if has_key(a:msg.body, "breakpoints")
    let brks = a:msg.body.breakpoints
    let brk = brks[0]
    let info[0] = 1
    let info[1] = brk.id  " breakpoint
    let info[2] = "" " filename
    let info[3] = brk.line  " lineno
    let info[4] = 0
  endif

  return info
endfunction

function s:LspProcessInput(self, cmdstr) abort
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

    :call add(cmds, [a:self.Print, a:cmdstr])
  else

    :call add(cmds, [a:self.Call, a:cmdstr])
  endif

  return cmds
endfunction

function s:LspDispose(self) abort
endfunction

