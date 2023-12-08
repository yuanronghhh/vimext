vim9script

export class GccDbg
  this.proto: any = v:null
  this.name = "gdb"

  def new(proto: any)
    this.proto = proto
  enddef

  def SetConfig(prompt: any, proto: any)
    if has("win32")
      call prompt.Send(prompt, proto.Set . " new-console on")
      call prompt.Send(prompt, proto.Set . " print pretty on")
      call prompt.Send(prompt, proto.Set . " breakpoint pending on")
    else
      call prompt.Send(prompt, "set breakpoint pending on")
    endif
  enddef

  def FilterStart(term: any)
    var try_count = 0

    while 1
      if !term.Running(term)
        call vimext#logger#Error('Exited unexpectedly: '. join(cmd, " "))
        return 0
      endif

      for lnum in range(1, 200)
        var lstr = term.GetLine(term, lnum)
        if lstr =~ 'startupdone'
          var try_count = 9999
          break
        endif
      endfor
      var try_count += 1
      if try_count > 300
        " done or give up after five seconds
        break
      endif
      sleep 10m
    endwhile
  enddef

  def GetCmd(output_term: any, args: list<string>)
    var tty = output_term.tty
    var protoname = this.proto.name

    return GetGccCmd(protoname, tty, args)
  enddef

  def GetGccCmd(protoname: string, tty: number, args: list<string>)
    var cmd = ["gdb"]
    cmd += ['-quiet']
    cmd += ['-iex', 'set pagination off']
    cmd += ['-iex', 'set mi-async on']

    if protoname == "mi2" && has("win32")
      cmd += ['--interpreter=mi2']
    else
      cmd += ['-tty', tty]
    endif
    cmd += args

    return cmd
  enddef

  def Dispose()
  enddef
endclass
