let s:self = v:null

" bridge
function s:StartBridge(self, output_term) abort
  startinsert
endfunction

" bridge
function s:BridgeCallback(cmd) abort
  let l:cmd = s:self.HandleInput(a:cmd)
  if l:cmd is v:null
    return
  endif

  call s:BridgeSend(s:self, l:cmd)
endfunction

function s:BridgeInterrupt() abort
  "call vimext#logger#Info("BridgeInterrupt")

  if s:pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(s:bridge_pid)
endfunction

function vimext#bridge#Ref() abort
  return s:self
endfunction

function vimext#bridge#Create(dbg, funcs) abort
  let l:self = v:null
  if has("win32")
    let l:self = vimext#prompt#Create(a:funcs)
  else
    let l:self = vimext#term#Create(a:funcs)
  endif

  if l:self is v:null
    return v:null
  endif

  if !has('terminal')
    call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  return l:self
endfunction

function s:Dispose(self) abort
endfunction
