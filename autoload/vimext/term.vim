let s:self = v:null

" term
function vimext#term#New(cmd, opts) abort
  let l:info = {
        \ "buf": v:null,
        \ "winid": v:null,
        \ "job": v:null,
        \ "tty": v:null,
        \ }

  let l:info.buf = term_start(cmd, opts)
  if l:info.buf == 0
    return v:null
  endif

  let l:info.winid = win_getid()
  let l:info.job = term_getjob(l:term_buf)
  let l:info.tty = job_info(l:info[2])['tty_out']

  return l:info
endfunction



function vimext#term#InitTerm(self) abort
  let l:cmd = a:self.dbg.GetCmd(a:self.dbg)

  " start buffer
  let l:term = vimext#term#New("None", {
        \ 'term_name': 'term debugger',
        \ 'vertical': 1,
        \ })
  if l:term == v:null
    call vimext#logger#Error('Failed to start debugger term')
    return 0
  endif

  " command window
  let l:cmd_term = vimext#term#New("None", {
        \ 'term_name': 'cmd term',
        \ 'out_cb': a:self.HandleOutput,
        \ 'hidden': 1,
        \ })
  if l:cmd_term == v:null
    call vimext#logger#Error('Failed to start cmd term')
    return 0
  endif

  let l:dbg_term = vimext#term#New(l:cmd, {
        \ 'term_finish': 'close'
        \ 'exit_cb': a:self.HandleExit
        \ })
  if l:dbg_term == v:null
    call vimext#logger#Error('Failed to start dbg term')
    return 0
  endif

  if !vimext#term#Running(l:dbg_term)
    call vimext#logger#Error(join(l:cmd, " ") . ' exited unexpectedly')
    return 0
  endif
  set filetype=termdebug

  return 1
endfunction

function s:StartTerm(self) abort
endfunction

function s:TermSend(self, cmd) abort
  call term_sendkeys(a:self.cmd_buf, a:cmd . "\r")
endfunction

function vimext#term#PrintOutput(self, win, msg) abort
  let l:cwin = win_getid()

  call win_gotoid(a:win)
  call append(line('$') - 1, a:msg)

  call win_gotoid(l:cwin)
endfunction

" term
function s:TermCallback(cmd) abort
  let l:cmd = s:self.HandleInput(a:cmd)
  if l:cmd == v:null
    return
  endif

  call s:TermSend(s:self, l:cmd)
endfunction

function s:TermInterrupt() abort
  "call vimext#logger#Info("TermInterrupt")

  if s:pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(s:term_pid)
endfunction

function vimext#term#Create(dbg, funcs) abort
  let l:self = {
        \ "dbg": a:dbg,
        \ "mode": v:null,
        \ "dbg_channel": v:null,
        \ "job": v:null,
        \ "term_pid": 0,
        \ "term_buf": 0,
        \ "cmd_buf": 0,
        \ "term_tty": 0,
        \ "Start": function("s:StartTerm"),
        \ "Callback": function("s:TermCallback"),
        \ "Interrupt": function("s:TermInterrupt"),
        \ 'HandleExit': get(a:funcs, "HandleExit", v:null),
        \ "HandleInput": get(a:funcs, "HandleInput", v:null),
        \ 'HandleOutput': get(a:funcs, "HandleOutput", v:null),
        \ "Send": function("s:TermSend"),
        \ "Dispose": function("s:Dispose"),
        \ }

  if vimext#term#InitTerm(l:self) == 0
    return v:null
  endif
  let s:self = l:self

  return l:self
endfunction

function s:Dispose(self) abort
  if a:self == v:null
    return
  endif

  call job_stop(a:self.job, "kill")
  call vimext#buffer#Wipe(a:self.term_buf)

  unlet a:self.term_buf
  let s:self = v:null
endfunction
