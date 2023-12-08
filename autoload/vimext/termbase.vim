vim9script

import "./logger.vim" as Logger


export class TermBase
  def new(cmd: string, opts: dict<any>)
    this.buf = v:null
    this.job = v:null
    this.tty = v:null
    this.winid = v:null

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

  def GetLine(lnum: number)
  enddef

  def Send(cmd: string)
  enddef

  def Running()
    if job_status(this.job) !=# 'run'
      return v:false
    endif

    return v:true
  enddef

  def Print(msg: string)
  enddef
endclass

export def ToTermBase(o: TermBase): TermBase
  return o
enddef
