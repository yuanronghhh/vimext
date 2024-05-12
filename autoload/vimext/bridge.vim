let s:self = v:null

" bridge
function s:BridgeCallback(cmd) abort
  let cmd = s:self.HandleInput(a:cmd)
  if cmd is v:null
    return
  endif

  :call s:BridgeSend(s:self, cmd)
endfunction

function s:BridgeInterrupt() abort
  if s:pid == 0
    :call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  :call debugbreak(s:bridge_pid)
endfunction

function vimext#bridge#Ref() abort
  return s:self
endfunction

function vimext#bridge#Create(dbg, funcs) abort
  let self = v:null
  if has("win32") || a:dbg.name == "netcoredbg"
    let self = vimext#prompt#Create(a:funcs)
  else
    let self = vimext#term#Create(a:funcs)
  endif

  if self is v:null
    return v:null
  endif

  if !has('terminal')
    :call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  return self
endfunction

function s:Dispose(self) abort
endfunction
