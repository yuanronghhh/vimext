let s:self = v:null
let s:parent = v:null

" Term Start
function s:GetWinID(self) abort
  return a:self.winid
endfunction

function s:GoTerm(self) abort
  return win_gotoid(a:self.winid)
endfunction

function s:Destroy(self) abort
  call job_stop(a:self.job, "kill")
  call vimext#buffer#Wipe(a:self.buf)
endfunction

function vimext#term#New(cmd, opts) abort
  let l:info = {
        \ "buf": v:null,
        \ "job": v:null,
        \ "tty": v:null,
        \ "winid": win_getid()
        \ "GetWinID": function("s:GetWinID"),
        \ "GoTerm": function("s:GoTerm"),
        \ "Dispose": function("s:Destroy")
        \ }

  let l:info.buf = term_start(a:cmd, a:opts)
  if l:info.buf == 0
    return v:null
  endif

  let l:info.job = term_getjob(l:info.buf)
  if l:info.job is v:null
    return v:null
  endif
  let l:info.tty = job_info(l:info.job)['tty_out']

  return l:info
endfunction

function vimext#term#Send(self, cmd) abort
  call term_sendkeys(a:self.buf, a:cmd . "\r")
endfunction

function vimext#term#Running(self) abort
  if job_status(a:self.job) !=# 'run'
    return v:false
  endif

  return v:true
endfunction

function s:NewCmd(self) abort
  let l:cmd_term = vimext#term#New("NONE", {
        \ 'term_name': 'cmd term',
        \ 'out_cb': function("s:TermOut"),
        \ 'hidden': 1,
        \ })
  if l:cmd_term is v:null
    call vimext#logger#Error('Failed to start cmd term')
    return v:null
  endif
  return l:cmd_term
endfunction

function s:NewDebug(self) abort
  " start buffer
  let l:term = vimext#term#New("NONE", {
        \ 'term_name': 'term debugger',
        \ 'vertical': 1,
        \ })
  if l:term is v:null
    call vimext#logger#Error('Failed to start debugger term')
    return v:null
  endif

  return  l:term
endfunction
"Term end

function s:TermOut(channel, data) abort
  let msgs = split(a:data, '\r')

  for l:msg in msgs
    call s:self.HandleOutput(a:channel, l:msg)
  endfor
endfunction

function s:StartTerm(self) abort
  let l:cmd = a:self.dbg.GetCmd(a:self.dbg, {
        \ "tty" : a:self.cmd_term.tty
        \ })

  let l:dbg_term = vimext#term#New(l:cmd, {
        \ 'term_finish': 'close',
        \ 'exit_cb': a:self.HandleExit
        \ })
  if l:dbg_term is v:null
    call vimext#logger#Error('Failed to start dbg term')
    return 0
  endif
  let a:self.dbg_term = l:dbg_term

  if !vimext#term#Running(a:self.dbg_term)
    call vimext#logger#Error('Exited unexpectedly: '. join(l:cmd, " "))
    return 0
  endif
  set filetype=termdebug
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
  if l:cmd is v:null
    return
  endif

  call vimext#term#Send(s:self.cmd_term.buf, l:cmd)
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
        \ "cmd_term": v:null,
        \ "term": v:null,
        \ "NewCmd": function("s:NewCmd"),
        \ "NewDebug": function("s:NewDebug"),
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
  let s:parent = vimext#bridge#Ref()

  return l:self
endfunction

function s:TermSend(self, cmd) abort
  call vimext#term#Send(a:self.cmd_term, a:cmd)
endfunction

function s:Dispose(self) abort
  if a:self is v:null
    return
  endif

  call vimext#term#Destroy(a:self.term)
  call vimext#term#Destroy(a:self.cmd_term)

  unlet a:self.term_buf
  let s:self = v:null
endfunction
