vim9script

var self = v:null
var parent = v:null


# term start
def GetWinID()
  return self.winid
enddef

def Go(self)
  return win_gotoid(self.winid)
enddef

def Destroy()
  if self.mode == 1
    call job_stop(self.job, "kill")
  endif

  call vimext#buffer#Wipe(self.buf)
enddef

def vimext#prompt#New(mode, name, cmd, opts)
  var self = {
        \ "name": name,
        \ "mode": mode,
        \ "channel": v:null,
        \ "job": v:null,
        \ "buf": v:null,
        \ "tty": v:null,
        \ "winid": v:null,
        \ "GetWinID": function("GetWinID"),
        \ "Go": function("Go"),
        \ "Send": function("Send"),
        \ "Print": function("Print"),
        \ "Running": function("Running"),
        \ "Destroy": function("Destroy")
        \ }

  if mode == 1
    var job = job_start(cmd, {
          \ "exit_cb":  get(opts, "exit_cb", v:null),
          \ "out_cb": get(opts, "out_cb", v:null)
          \ })
    if l:job is v:null
      return v:null
    endif

    var winid = vimext#buffer#NewWindow(name, 2, v:null)
    call win_gotoid(l:winid)

    var self.winid = l:winid
    var self.buf = bufnr("%")

    var self.job = l:job
    var self.channel = job_getchannel(l:job)

    setlocal buftype=prompt
    call prompt_setprompt(l:self.buf, '(gdb) ')
    call prompt_setcallback(l:self.buf, get(opts, "callback", v:null))
    call prompt_setinterrupt(l:self.buf, get(opts, "interrupt", v:null))
    startinsert
  elseif mode == 2
    var winid = vimext#buffer#NewWindow(name, 1, v:null)
    call win_gotoid(l:winid)

    var self.winid = l:winid
    var self.buf = bufnr('%')
  else
    return v:null
  endif

  return l:self
enddef

def Send(self, cmd)
  if self.channel is v:null
    return
  endif

  call ch_sendraw(self.channel, cmd . "\n")
enddef

def Running(self)
  if job_status(self.job) !=# 'run'
    return v:false
  endif

  return v:true
enddef

def NewDbg(cmd)
  var term = vimext#prompt#New(1, "Dbg", cmd, {
        \ "exit_cb": self.HandleExit,
        \ "out_cb": self.HandleOutput,
        \ "callback": self.HandleInput,
        \ "interrupt": self.Interrupt,
        \ })

  return l:term
enddef

def NewProg()
  var term = vimext#prompt#New(2, "Output", v:null, {})
  if l:term is v:null
    call vimext#logger#Error('Failed to start debugger term')
    return v:null
  endif

  return  l:term
enddef

def Print(self, msg)
  var cwin = win_getid()

  call win_gotoid(self.winid)
  call append(line('$') - 1, msg)

  call win_gotoid(l:cwin)
enddef
" term end"

" prompt
def PromptInterrupt()
  "call vimext#logger#Info("PromptInterrupt")

  if pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(prompt_pid)
enddef

" prompt manager
def vimext#prompt#Create(funcs)
  var self = {
        \ "prompt_pid": 0,
        \ "prompt_buf": 0,
        \ "NewDbg": function("NewDbg"),
        \ "NewProg": function("NewProg"),
        \ "Interrupt": function("PromptInterrupt"),
        \ 'HandleExit': get(funcs, "HandleExit", v:null),
        \ "HandleInput": get(funcs, "HandleInput", v:null),
        \ 'HandleOutput': get(funcs, "HandleOutput", v:null),
        \ "Dispose": function("Dispose"),
        \ }

  if !has('terminal')
    call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  var self = l:self
  var parent = vimext#bridge#Ref()

  return l:self
enddef

def Dispose()
  if self is v:null
    return
  endif

  var self = v:null
enddef
