"""
" refactor version of termdbug
"""
let s:self = v:null
let s:parent = v:null


" term start
function s:GetWinID(self) abort
  return a:self.winid
endfunction

function s:Go(self) abort
  return win_gotoid(a:self.winid)
endfunction

function s:Destroy(self) abort
  if a:self.mode == 1
    :call job_stop(a:self.job, "kill")
  endif

  :call vimext#buffer#Wipe(a:self.buf)
endfunction

function vimext#prompt#New(mode, name, cmd, opts) abort
  let self = {
        \ "name": a:name,
        \ "mode": a:mode,
        \ "channel": v:null,
        \ "job": v:null,
        \ "buf": v:null,
        \ "tty": v:null,
        \ "winid": v:null,
        \ "GetWinID": function("s:GetWinID"),
        \ "Go": function("s:Go"),
        \ "Send": function("s:Send"),
        \ "Print": function("s:Print"),
        \ "Running": function("s:Running"),
        \ "Destroy": function("s:Destroy")
        \ }

  if a:mode == 1
    let job = job_start(a:cmd, {
          \ "exit_cb":  get(a:opts, "exit_cb", v:null),
          \ "out_cb": get(a:opts, "out_cb", v:null)
          \ })

    if job_status(job) == "fail"
      return v:null
    endif

    let winid = vimext#buffer#NewWindow(a:name, 2, v:null)
    :call win_gotoid(winid)

    let self.winid = winid
    let self.buf = bufnr("%")

    let self.job = job
    let self.channel = job_getchannel(job)

    setlocal buftype=prompt
    :call prompt_setprompt(self.buf, '(gdb) ')
    :call prompt_setcallback(self.buf, get(a:opts, "callback", v:null))
    :call prompt_setinterrupt(self.buf, get(a:opts, "interrupt", v:null))
    startinsert
  elseif a:mode == 2
    let winid = vimext#buffer#NewWindow(a:name, 1, v:null)
    :call win_gotoid(winid)

    let self.winid = winid
    let self.buf = bufnr('%')
  else
    return v:null
  endif

  return self
endfunction

function s:Send(self, cmd) abort
  if a:self.channel is v:null
    return
  endif

  ":call vimext#logger#Info(a:cmd)
  :call ch_sendraw(a:self.channel, a:cmd . "\n")
endfunction

function s:Running(self) abort
  if job_status(a:self.job) !=# 'run'
    return v:false
  endif

  return v:true
endfunction

function s:NewDbg(self, cmd) abort
  let term = vimext#prompt#New(1, "Dbg", a:cmd, {
        \ "exit_cb": a:self.HandleExit,
        \ "out_cb": a:self.HandleOutput,
        \ "callback": a:self.HandleInput,
        \ "interrupt": a:self.Interrupt,
        \ })

  return term
endfunction

function s:NewProg() abort
  let term = vimext#prompt#New(2, "Output", v:null, {})
  if term is v:null
    :call vimext#logger#Error('Failed to start debugger term')
    return v:null
  endif

  return  term
endfunction

function s:Print(self, msgs) abort
  let cwin = win_getid()
  :call win_gotoid(a:self.winid)

  :call append(line('$') - 1, a:msgs)

  :call setcursorcharpos('$', 1)
  :call win_gotoid(cwin)
endfunction
" term end"

" prompt
function s:PromptInterrupt() abort
  if s:pid == 0
    :call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  :call debugbreak(s:prompt_pid)
endfunction

" prompt manager
function vimext#prompt#Create(funcs) abort
  let self = {
        \ "prompt_pid": 0,
        \ "prompt_buf": 0,
        \ "NewDbg": function("s:NewDbg"),
        \ "NewProg": function("s:NewProg"),
        \ "Interrupt": function("s:PromptInterrupt"),
        \ 'HandleExit': get(a:funcs, "HandleExit", v:null),
        \ "HandleInput": get(a:funcs, "HandleInput", v:null),
        \ 'HandleOutput': get(a:funcs, "HandleOutput", v:null),
        \ "Dispose": function("s:Dispose"),
        \ }

  if !has('terminal')
    :call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  let s:self = self
  let s:parent = vimext#bridge#Ref()

  return self
endfunction

function s:Dispose(self) abort
  if a:self is v:null
    return
  endif

  let s:self = v:null
endfunction
