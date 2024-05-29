let s:self = v:null
let s:state = 0
let s:lastcmd = "next"

" dap protocol start
function vimext#dapproto#Create() abort
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

function s:DapBreak(self, args) abort
endfunction

function s:DapClear(self, args) abort
endfunction

function s:DapArguments(self, args) abort
endfunction

function s:DapAbort(self, args) abort
endfunction

function s:DapRun(self, args) abort
endfunction

function s:DapStep(self, args) abort
endfunction

function s:DapNext(self, args) abort
endfunction

function s:DapFinish(self, args) abort
endfunction

function s:DapInterrupt(self, args) abort
endfunction

function s:DapContinue(self, args) abort
endfunction

function s:DapUntil(self, args) abort
endfunction

function s:DapEval(self, args) abort
endfunction

function s:DapDataEvaluate(self, args) abort
endfunction

function s:DapVarCreate(self, args) abort
endfunction

function s:DapVarChildren(self, args) abort
endfunction

function s:DapFrame(self, args) abort
endfunction

function s:DapConsole(self, args) abort
endfunction

function s:DapAttach(self, args) abort
endfunction

function s:DapSource(self, args) abort
endfunction

function s:DapSet(self, args) abort
endfunction

function s:DapExit(self, args) abort
endfunction

function s:DapSaveBreakoints(self, args) abort
endfunction

function s:DapStart(self, args) abort
endfunction

function s:DapCall(self, args) abort
endfunction

function s:DapDisassemble(self, args) abort
endfunction

function s:DapPrint(self, args) abort
endfunction

function s:DapProcessOutput(self, args) abort
endfunction

function s:DapProcessInput(self, cmdstr) abort
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

function s:DapDispose(self, args) abort
endfunction

