vim9script

var self = v:null

import "./logger.vim" as Logger

class Term
  def new(cmd: string, opts: dict<any>)
    this.buf = v:null
    this.job = v:null
    this.tty = v:null
    this.winid = v:null
    this.GetWinID = function("GetWinID")
    this.Go = function("Go")
    this.GetLine = function("GetLine")
    this.Send = function("Send")
    this.Print = function("Print")
    this.Running = function("Running")
    this.Destroy = function("Destroy")

    var this.buf = term_start(cmd, opts)
    if this.buf == 0
      return v:null
    endif

    var winid = win_getid()

    this.job = term_getjob(this.buf)
    if this.job is v:null
      return v:null
    endif

    this.tty = job_info(this.job)['tty_out']
    this.winid = winid

    return info
  enddef


  def GetWinID()
    return this.winid
  enddef

  def Go()
    return win_gotoid(this.winid)
  enddef

  def Destroy()
    call job_stop(this.job, "kill")
    call vimext#buffer#Wipe(this.buf)
  enddef

  def GetLine(lnum: number)
    return term_getline(this.buf, lnum)
  enddef

  def Send(cmd: string)
    # call Logger.Info("[cmd] " . cmd)
    call term_sendkeys(this.buf, cmd . "\n")
  enddef

  def Running()
    if job_status(this.job) !=# 'run'
      return v:false
    endif

    return v:true
  enddef

  def Print(msg: string)
    # call this.Send(this, msg)
  enddef
endclass

def NewDbgTerm(cmd: string, out_func: any, exit_func: any)
  var cmd_term = New("NONE", {
        \ 'term_name': 'cmd hidden term',
        \ 'out_cb': out_func,
        \ 'hidden': 1,
        \ })
  if cmd_term is v:null
    call Logger.Error('Failed to start cmd term')
    return v:null
  endif

  var dbg_term = New(cmd, {
        \ 'term_finish': 'close',
        \ 'exit_cb': exit_func,
        \ })
  if dbg_term is v:null
    call Logger.Error('Failed to start dbg term')
    return v:null
  endif

  # cmd_term is hidden
  var cmd_term.winid = dbg_term.winid

  call dbg_term.Send(dbg_term, 'server new-ui mi ' . cmd_term.tty)

  return cmd_term
enddef

def NewDbg(cmd: string)
  return NewDbgTerm(cmd,
        \ function("TermOut"),
        \ function("TermExit")
        \ )
enddef

def NewProg()
  " start buffer
  var term = New("NONE", {
        \ 'term_name': 'term debugger',
        \ 'vertical': 1,
        \ })
  if term is v:null
    call Logger.Error('Failed to start debugger term')
    return v:null
  endif

  return  term
enddef

def TermOut(channel: channel, data: string)
  var msgs = split(data, "\r\n")

  for msg in msgs
    call self.HandleOutput(channel, msg)
  endfor
enddef

# term
class TermManager
  def new(param: dict<any>)
    this.term_pid = 0
    this.NewProg = function("NewProg")
    this.NewDbg = function("NewDbg")
    this.HandleExit = get(param, "HandleExit", v:null)
    this.HandleInput = get(param, "HandleInput", v:null)
    this.HandleOutput = get(param, "HandleOutput", v:null)

    self = this
  enddef

  def TermExit(job: job, status: number)
    call this.HandleExit(job, status)
  enddef

  def Dispose()
  enddef
endclass
