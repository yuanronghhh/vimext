vim9script

import "./buffer.vim" as Buffer
import "./logger.vim" as Logger

var self = v:null

class Prompt
  def new(mode: number, name: string, cmd: string, opts: dict<any>)
    this.name = name
    this.mode = mode
    this.channel = v:null
    this.job = v:null
    this.buf = v:null
    this.tty = v:null
    this.winid = v:null
    this.GetWinID = function("GetWinID")
    this.Go = function("Go")
    this.Send = function("Send")
    this.Print = function("Print")
    this.Running = function("Running")
    this.Destroy = function("Destroy")

    var winid = 0
    if mode == 1
      var job = job_start(cmd, {
            \ "exit_cb":  get(opts, "exit_cb", v:null),
            \ "out_cb": get(opts, "out_cb", v:null)
            \ })
      if job is v:null
        return v:null
      endif

      winid = Buffer.NewWindow(name, 2, v:null)
      call win_gotoid(winid)

      this.winid = winid
      this.buf = bufnr("%")

      this.job = job
      this.channel = job_getchannel(job)

      setlocal buftype=prompt
      call prompt_setprompt(this.buf, '(gdb) ')
      call prompt_setcallback(this.buf, get(opts, "callback", v:null))
      call prompt_setinterrupt(this.buf, get(opts, "interrupt", v:null))
      startinsert
    elseif mode == 2
      winid = Buffer.NewWindow(name, 1, v:null)
      call win_gotoid(winid)

      this.winid = winid
      this.buf = bufnr('%')
    else
      return v:null
    endif
  enddef

  def GetWinID()
    return this.winid
  enddef

  def Go()
    return win_gotoid(this.winid)
  enddef

  def Destroy()
    if this.mode == 1
      call job_stop(this.job, "kill")
    endif

    call Buffer.Wipe(this.buf)
  enddef

  def Send(cmd: string)
    if this.channel is v:null
      return
    endif

    call ch_sendraw(this.channel, cmd . "\n")
  enddef

  def Running()
    if job_status(this.job) !=# 'run'
      return v:false
    endif

    return v:true
  enddef

  def Print(msg: string)
    var cwin = win_getid()

    call win_gotoid(this.winid)
    call append(line('$') - 1, msg)

    call win_gotoid(cwin)
  enddef
endclass

export def NewDbg(cmd: string)
  var term = Prompt.new(1, "Dbg", cmd, {
        \ "exit_cb": this.HandleExit,
        \ "out_cb": this.HandleOutput,
        \ "callback": this.HandleInput,
        \ "interrupt": this.Interrupt,
        \ })

  return term
enddef

def NewProg()
  var term = Prompt.new(2, "Output", v:null, {})
  if term is v:null
    call Logger.Error('Failed to start debugger term')
    return v:null
  endif

  return term
enddef

# prompt
def PromptInterrupt()
  # call Logger.Info("PromptInterrupt")

  if pid == 0
    call Logger.Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(prompt_pid)
enddef

# prompt manager
export def Create(funcs: dict<any>)
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
    call Logger.Error("+terminal not enabled in vim")
    return v:null
  endif

  var self = self

  return self
enddef

def Dispose()
  if self is v:null
    return
  endif

  var self = v:null
enddef
