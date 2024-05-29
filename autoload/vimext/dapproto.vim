let s:self = v:null
let s:state = 0
let s:lastcmd = "next"

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

function s:DapProcessInput(self, args) abort
endfunction

function s:DapDispose(self, args) abort
endfunction

