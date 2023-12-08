vim9script

import "./buffer.vim" as Buffer
import "./logger.vim" as Logger
import "./termbase.vim" as TermBase


export class Prompt extends TermBase.TermBase
  this.name = name
  this.mode = mode
  this.channel = v:null
  this.job = v:null
  this.buf = v:null
  this.tty = v:null
  this.winid = v:null

  def new(mode: number, name: string, cmd: string, opts: dict<any>)
    this.name = name
    this.mode = mode

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

export class Manager
  this.pid = 0
  this.HandleExit: any = v:null
  this.HandleInput: any = v:null
  this.HandleOutput: any = v:null
  this.HandleInterrupt: any = v:null

  def new(funcs: dict<any>)
    this.HandleExit = get(funcs, "HandleExit", v:null)
    this.HandleInput = get(funcs, "HandleInput", v:null)
    this.HandleOutput = get(funcs, "HandleOutput", v:null)

    if !has('terminal')
      call Logger.Error("+terminal not enabled in vim")
    endif
  enddef

  def PromptInterrupt()
    if this.pid == 0
      call Logger.Error('Cannot interrupt, not find a process ID')
      return
    endif

    call debugbreak(this.pid)
  enddef

  def NewDbg(cmd: string): any
    var term = Prompt.new(1, "Dbg", cmd, {
          \ "exit_cb": this.HandleExit,
          \ "out_cb": this.HandleOutput,
          \ "callback": this.HandleInput,
          \ "interrupt": this.HandleInterrupt,
          \ })

    return term
  enddef

  def NewProg(): any
    var term = Prompt.new(2, "Output", v:null, {})
    if term == v:null
      call Logger.Error('Failed to start debugger term')
      return v:null
    endif

    return term
  enddef

  def Dispose()
  enddef
endclass

export def ToTerm(o: Prompt): Prompt
  return o
enddef

export def ToManager(o: Manager): Manager
  return o
enddef
