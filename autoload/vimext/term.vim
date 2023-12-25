let s:self = v:null

" Term Start
function s:GetWinID(self) abort
  return a:self.winid
endfunction

function s:Go(self) abort
  return win_gotoid(a:self.winid)
endfunction

function s:Destroy(self) abort
  call job_stop(a:self.job, "kill")
  call vimext#buffer#Wipe(a:self.buf)
endfunction

function s:GetLine(self, lnum) abort
  return term_getline(a:self.buf, a:lnum)
endfunction

function vimext#term#New(cmd, opts) abort
  let info = {
        \ "buf": v:null,
        \ "job": v:null,
        \ "tty": v:null,
        \ "winid": v:null,
        \ "GetWinID": function("s:GetWinID"),
        \ "Go": function("s:Go"),
        \ "GetLine": function("s:GetLine"),
        \ "Send": function("s:Send"),
        \ "Print": function("s:Print"),
        \ "Running": function("s:Running"),
        \ "Destroy": function("s:Destroy")
        \ }

  let info.buf = term_start(a:cmd, a:opts)
  if info.buf == 0
    return v:null
  endif

  let winid = win_getid()
  let info.job = term_getjob(info.buf)
  if info.job is v:null
    return v:null
  endif
  let info.tty = job_info(info.job)['tty_out']
  let info.winid = winid

  return info
endfunction

function s:Send(self, cmd) abort
  call term_sendkeys(a:self.buf, a:cmd . "\n")
endfunction

function s:Running(self) abort
  if job_status(a:self.job) !=# 'run'
    return v:false
  endif

  return v:true
endfunction

function s:NewDbgTerm(cmd, out_func, exit_func) abort
  let cmd_term = vimext#term#New("NONE", {
        \ 'term_name': 'cmd hidden term',
        \ 'out_cb': a:out_func,
        \ 'hidden': 1,
        \ })
  if cmd_term is v:null
    call vimext#logger#Error('Failed to start cmd term')
    return v:null
  endif

  let dbg_term = vimext#term#New(a:cmd, {
        \ 'term_finish': 'close',
        \ 'exit_cb': a:exit_func,
        \ })
  if dbg_term is v:null
    call vimext#logger#Error('Failed to start dbg term')
    return v:null
  endif

  " cmd_term is hidden
  let cmd_term.winid = dbg_term.winid

  call dbg_term.Send(dbg_term, 'server new-ui mi ' . cmd_term.tty)

  return cmd_term
endfunction

function s:NewDbg(self, cmd) abort
  return s:NewDbgTerm(a:cmd,
        \ function("s:TermOut"),
        \ function("s:TermExit")
        \ )
endfunction

function s:NewProg() abort
  " start buffer
  let term = vimext#term#New("NONE", {
        \ 'term_name': 'term debugger',
        \ 'vertical': 1,
        \ })
  if term is v:null
    call vimext#logger#Error('Failed to start debugger term')
    return v:null
  endif

  return  term
endfunction

function s:Print(self, msg) abort
  "call s:Send(a:self, a:msg)
endfunction
"Term end

function s:TermOut(channel, data) abort
  let msgs = split(a:data, "\r\n")

  for msg in msgs
    call s:self.HandleOutput(a:channel, msg)
  endfor
endfunction

" term
function s:TermExit(job, status) abort
  call s:self.HandleExit(a:job, a:status)
endfunction

function vimext#term#Create(param) abort
  let self = {
        \ "term_pid": 0,
        \ "NewProg": function("s:NewProg"),
        \ "NewDbg": function("s:NewDbg"),
        \ 'HandleExit': get(a:param, "HandleExit", v:null),
        \ "HandleInput": get(a:param, "HandleInput", v:null),
        \ 'HandleOutput': get(a:param, "HandleOutput", v:null),
        \ "Dispose": function("s:Dispose"),
        \ }
  let s:self = self

  return self
endfunction

function s:Dispose(self) abort
endfunction
