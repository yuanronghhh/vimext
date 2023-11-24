let s:self = v:null

" bridge
function s:StartBridge(self) abort
  startinsert
endfunction

function s:BridgeSend(self, cmd) abort
  call term_sendkeys(a:self.cmd_buf, a:cmd . "\r")
endfunction

function vimext#bridge#PrintOutput(self, win, msg) abort
  let l:cwin = win_getid()

  call win_gotoid(a:win)
  call append(line('$') - 1, a:msg)

  call win_gotoid(l:cwin)
endfunction

" bridge
function s:BridgeCallback(cmd) abort
  let l:cmd = s:self.HandleInput(a:cmd)
  if l:cmd == v:null
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
  let l:self = {
        \ "Start": function("s:StartBridge")
        \ }
  let s:self = l:self

  call vimext#debug#Highlight(1, '', &background)
  if has("win32")
    let l:self = vimext#prompt#Create(a:dbg, a:funcs)
  else
    let l:self = vimext#term#Create(a:dbg, a:funcs)
  endif
  if l:self == v:null
    return v:null
  endif

  if !has('terminal')
    call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  return l:self
endfunction

function s:Dispose(self) abort
  if a:self == v:null
    return
  endif

  call job_stop(a:self.job, "kill")
  call vimext#buffer#Wipe(a:self.bridge_buf)

  unlet a:self.bridge_buf
  let s:self = v:null
endfunction
