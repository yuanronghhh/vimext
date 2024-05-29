let s:self = v:null

function vimext#dbg#Create(name, proto) abort
  let self = v:null

  if a:name == "netcoredbg"
    let self = vimext#netcoredbg#Create(a:proto)
  elseif a:name == "lldb"
    let self = vimext#lldb#Create(a:proto)
  elseif a:name == "gdb"
    let self = vimext#gccdbg#Create(a:proto)
  else
    return v:null
  endif
  let s:self = self

  return self
endfunction

function vimext#dbg#GetProtoByDbgName(dbgname) abort
  let protoname = v:null
  if a:dbgname == "gdb"
    let protoname = "mi2"
  elseif a:dbgname == "netcoredbg"
    let protoname = "mi"
  elseif a:dbgname == "lldb"
    let protoname = "dap"
  else
  endif

  return l:protoname
endfunction


function s:Dispose(self) abort
endfunction
