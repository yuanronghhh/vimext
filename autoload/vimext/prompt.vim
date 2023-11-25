"""
" refactor version of termdbug
"""
let s:self = v:null
let s:parent = v:null

function vimext#prompt#InitChannel(self) abort
  let l:cmd = a:self.dbg.GetCmd(a:self.dbg)
  let l:job = job_start(l:cmd, {
        \ "exit_cb": a:self.HandleExit,
        \ "out_cb": a:self.HandleOutput
        \ })

  if job_status(l:job) != "run"
    call vimext#logger#Error('Failed to start:'. join(l:cmd, ' '))
    return 0
  endif

  let a:self.job = l:job
  let a:self.dbg_channel = job_getchannel(l:job)
  return 1
endfunction

function s:StartPrompt(self) abort
  let a:self.prompt_buf = bufnr('%')

  call prompt_setprompt(a:self.prompt_buf, '(gdb) ')
  setlocal buftype=prompt
  call prompt_setcallback(a:self.prompt_buf, a:self["Callback"])
  call prompt_setinterrupt(a:self.prompt_buf, a:self["Interrupt"])

  call s:parent.Start(s:parent)
endfunction

function s:PromptSend(self, cmd) abort
  call ch_sendraw(a:self.dbg_channel, a:cmd."\n")
endfunction

function vimext#prompt#PrintOutput(self, win, msg) abort
  let l:cwin = win_getid()

  call win_gotoid(a:win)
  call append(line('$') - 1, a:msg)

  call win_gotoid(l:cwin)
endfunction

" prompt
function s:PromptCallback(cmd) abort
  let l:cmd = s:self.HandleInput(a:cmd)
  if l:cmd is v:null
    return
  endif

  call s:PromptSend(s:self, l:cmd)
endfunction

function s:PromptInterrupt() abort
  "call vimext#logger#Info("PromptInterrupt")

  if s:pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(s:prompt_pid)
endfunction

function vimext#prompt#Create(dbg, funcs) abort
  let l:self = {
        \ "dbg": a:dbg,
        \ "mode": v:null,
        \ "dbg_channel": v:null,
        \ "job": v:null,
        \ "prompt_pid": 0,
        \ "prompt_buf": 0,
        \ "Start": function("s:StartPrompt"),
        \ "Callback": function("s:PromptCallback"),
        \ "Interrupt": function("s:PromptInterrupt"),
        \ 'HandleExit': get(a:funcs, "HandleExit", v:null),
        \ "HandleInput": get(a:funcs, "HandleInput", v:null),
        \ 'HandleOutput': get(a:funcs, "HandleOutput", v:null),
        \ "Send": function("s:PromptSend"),
        \ "Dispose": function("s:Dispose"),
        \ }

  if !has('terminal')
    call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  if vimext#prompt#InitChannel(l:self) == 0
    return v:null
  endif
  let s:self = l:self
  let s:parent = vimext#bridge#Ref()

  return l:self
endfunction

function s:Dispose(self) abort
  if a:self is v:null
    return
  endif

  call vimext#buffer#Wipe(a:self.prompt_buf)
  call job_stop(a:self.job, "kill")

  unlet a:self.prompt_buf
  let s:self = v:null
endfunction
