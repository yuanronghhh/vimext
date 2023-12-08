vim9script

import "./bridge.vim" as Bridge
import "./logger.vim" as Logger
import "./sign.vim" as Sign
import "./proto.vim" as Proto
import "./gccdbg.vim" as GccDbg
import "./netcoredbg.vim" as NetCoreDbg

var self = v:null

export class Runner
  this.gdb_cfg = v:null
  this.proto = v:null
  this.bridge = v:null
  this.dbg = dbg
  this.dbg_term = v:null
  this.cmd_term = v:null
  this.source_viewer = v:null
  this.asm_viewer = v:null

  def new(proto: any, dbg: any)
    this.gdb_cfg = g:vim_session .. "/gdb.cfg"
    this.proto = proto
  enddef
endclass

export class Manager
  this.proto = v:null
  this.dbg = v:null
  this.bridge = v:null
  this.dbg_term = v:null
  this.cmd_term = v:null
  this.source_viewer = v:null
  this.asm_viewer = v:null

  def new(lang: string, args: list<string>)
    var bridge: any = v:null
    var proto: any = v:null
    var dbg: any = v:null

    if self != v:null
      call Logger.Error("call not start two debugger")
      return
    endif

    Logger.Error(lang)
    # if lang == "csharp"
    #   proto = Proto.MIProto.new("mi")
    #   dbg = NetCoreDbg.NetCoreDbg.new(proto)
    # elseif lang == "c"
    #   proto = Proto.MIProto.new("mi2")
    #   dbg = GccDbg.GccDbg.new(proto)
    # else
    #   call Logger.Error("not correct language")
    #   return
    # endif

    # if dbg is v:null || proto is v:null
    #   call Logger.Error("dbg or proto not create successful in Runner.Manager")
    #   return
    # endif
    # this.proto = proto
    # this.dbg = dbg

    # var funcs = {
    #       \ 'HandleExit': function("PromptExit"),
    #       \ "HandleInput": function("PromptInput"),
    #       \ 'HandleOutput': function("PromptOut")
    #       \ }

    # call Sign.Init()

    # if exists('#User#DbgDebugStartPre')
    #   doauto <nomodeline> User DbgDebugStartPre
    # endif
    # var empty_win = win_getid()

    # var bridge = Bridge.Create(dbg, funcs)
    # var this.bridge = bridge

    # var cmd_term = bridge.NewProg()
    # var this.cmd_term = cmd_term

    # call win_execute(empty_win, "close")

    # var cmd = dbg.GetCmd(this.dbg, cmd_term, args)
    # var dbg_term = bridge.NewDbg(bridge, cmd)
    # var this.dbg_term = dbg_term

    # call dbg.SetConfig(dbg, dbg_term, proto)
    # call BreakPoint.Init()

    # if exists('#User#DbgDebugStartPost')
    #   doauto <nomodeline> User DbgDebugStartPost
    # endif
  enddef

  def Call(cmd: string, args: list<string>)
    if self is v:null
      return
    endif

    var term = this.dbg_term

    if args is v:null
      call term.Send(term, cmd)
    else
      call term.Send(term, cmd . " " . args)
    endif
  enddef

  def Dispose()
    call this.bridge.Dispose(this.bridge)
    call this.proto.Dispose(this.proto)
    call this.dbg.Dispose(this.dbg)

    call Sign.DeInit()
    call BreakPoint.DeInit()

    if this.source_viewer isnot v:null
      call this.source_viewer.Dispose(this.source_viewer)
      unvar this.source_viewer
    endif

    if this.asm_viewer isnot v:null
      call this.asm_viewer.Dispose(this.asm_viewer)
      unvar this.asm_viewer
    endif

    call this.cmd_term.Destroy(this.cmd_term)
    call this.dbg_term.Destroy(this.dbg_term)

    var self = v:null
  enddef

  def GetSouceWinPath()
    var winid = vimext#viewer#GetWinID(this.source_viewer)
    return vimext#buffer#GetNameByWinID(winid)
  enddef

  def Asm()
    if self is v:null
          \ || this.proto is v:null
          \ || this.dbg is v:null
      return
    endif

    if this.proto.name == "mi2" && this.dbg.name == "gdb"
    else
      return
    endif

    if this.source_viewer is v:null
      return
    endif

    if this.asm_viewer isnot v:null
      call vimext#viewer#Show(this.asm_viewer)
      call this.SetAsmEnv(this.asm_viewer)
    else
      var source_win = vimext#viewer#GetWinID(this.source_viewer)
      var asm_viewer = this.CreateAsmViewer(source_win)
      this.asm_viewer = asm_viewer
    endif

    call Call(this.proto.Disassemble, "$pc")
  enddef

  def Source()
    if this.source_viewer is v:null
      return
    endif

    call vimext#viewer#Show(this.source_viewer)
  enddef

  def Run(args: list<string>)
    var start = Proto.GetStart(this.proto)
    if start is v:null
      return
    endif

    if args isnot v:null
      if this.dbg.name == "gdb"
      else
        var args = vimext#debug#DecodeFilePath(a:args)
        if args[0] != "\""
          var args = "\"" . args . "\""
        endif

        call Call(this.proto.Arguments, args)
      endif
    endif

    call Call(this.proto.Start, v:null)
  enddef

  def Attach(pid: number)
    call Call(this.proto.Attach, pid)
  enddef

  def Restore()
    if !filereadable(s:gdb_cfg)
      call writefile([], gdb_cfg, "w")
    else
      if this.proto.name == "mi"
      else
        call Call(this.proto.Source, gdb_cfg)
      endif
    endif
  enddef

  def Next()
    call Call(this.proto.Next, v:null)
  enddef

  def Stop()
    call Call(this.proto.Stop, v:null)
  enddef

  def Step()
    call Call(this.proto.Step, v:null)
  enddef

  def Continue()
    call Call(this.proto.Continue, v:null)
  enddef

  def Break(args: list<string>)
    var info = BreakPoint.Parse(a:args)
    if info is v:null
      return
    endif

    if info[0] == 1
      var info[1] = this.GetSouceWinPath(this)

      var brk = BreakPoint.Get(info[1], info[2])
      if brk isnot v:null
        call BreakPoint.Delete(brk)
        call Call(this.proto.Clear, brk[1])
      else
        call DeleteBreakPointByFName(this, info[1], info[2])
      endif
    else
      call Call(this.proto.Break, info[1])
    endif
  enddef

  def Clear(args: list<string>)
    call Call(this.proto.Clear, args)
  enddef

  def Delete()
    call Call(this.proto.Delete, v:null)
  enddef

  def PromptExit(job: job, status: number)
    if exists('#User#DbgDebugStopPost')
      doauto <nomodeline> User DbgDebugStopPost
    endif
  enddef

  def PromptInput(cmd: string)
    var info = this.proto.ProcessInput(this.proto, cmd)

    if info[0] == 1 " quit
      if exists('#User#DbgDebugStopPre')
        doauto <nomodeline> User DbgDebugStopPre
      endif
    endif

    if info[0] == 6
      call this.Break(info[2])
      return v:null
    endif

    if info[0] == 7 " print
      if info[3] != 0
        call Call(info[3], v:null)
      endif
    endif

    call Call(info[1] . " " . info[2], v:null)
  enddef

  def DeleteBreakPointByFName(fname: string, lnum: number)
    var brk = BreakPoint.Get(a:fname, lnum)
    if brk is v:null
      call Call(this.proto.Break, fname . ":" . lnum)
    else
      call BreakPoint.Delete(brk)
    endif
  enddef

  def SetAsmEnv(viewer: any)
    call vimext#viewer#Go(a:viewer)
    :setlocal nowrap
    :setlocal number
    :setlocal noswapfile
    :setlocal buftype=nofile
    :setlocal filetype=asm
    :setlocal bufhidden=wipe
    :setlocal signcolumn=no
    :setlocal modifiable
    :setlocal nolist
  enddef

  def CreateAsmViewer(basewin: number)
    var viewer = vimext#viewer#CreateTextMode("asm", 3, basewin, 32)
    call this.SetAsmEnv(viewer)
    return viewer
  enddef

  def LoadSource(fname: string, lnum: number)
    if this.source_viewer is v:null
      var dbg_win = this.dbg_term.GetWinID(this.dbg_term)

      let this.source_viewer = vimext#viewer#CreateFileMode("source", 1, dbg_win, 31)
      call vimext#viewer#Go(this.source_viewer)
      execute "wincmd H"

      call vimext#viewer#LoadByFile(this.source_viewer, fname, lnum)
      call this.Restore()
    else
      call vimext#viewer#Show(this.source_viewer)
      call vimext#viewer#LoadByFile(this.source_viewer, fname, lnum)
    endif

    if vimext#viewer#IsShow(this.asm_viewer)
      call Call(this.proto.Disassemble, "$pc")
    endif
  enddef

  def PrintOutput(msg: string)
    var msg = vimext#proto#ProcessMsg(a:msg)
    if msg is v:null
      return
    endif

    var term = this.cmd_term
    call term.Print(term, msg)
  enddef

  def SaveBrks()
    call Call(this.proto.SaveBreakoints, gdb_cfg)
  enddef

  def PrintError(msg: string)
    var term = this.cmd_term
    call term.Print(term, msg)
  enddef

  def PromptOut(channe: channel, msg: string)
    if self is v:null
      return
    endif

    var info = this.proto.ProcessOutput(a:msg)
    if info is v:null
      return
    endif

    if info[0] == 1 " hit breakpoint
      call this.LoadSource(this, info[2], info[3])

    elseif info[0] == 4 " user set breakpoint
      "brkid,type,disp,enable,func,file,fullname,line
      call BreakPoint.Add(info[0:8])

    elseif info[0] == 5 " exit end stepping range
      call this.LoadSource(this, info[1], info[2])

    elseif info[0] == 8 " message
      call this.PrintOutput(this, info[1])

    elseif info[0] == 9 " entry-point-hit
      call this.LoadSource(this, info[1], info[2])

    elseif info[0] == 10 " error msg
      call this.PrintError(this, info[1])

    elseif info[0] == 11 " breakpoint delete
      call BreakPoint.DeleteID(info[1])

    elseif info[0] == 14 " asm break
      call vimext#viewer#SetSignText(this.asm_viewer, info[1])

    elseif info[0] == 15 " asm start
      call vimext#viewer#SetUniqueID(this.asm_viewer, info[1])

    elseif info[0] == 16 " asm end
      call vimext#viewer#SetLines(this.asm_viewer, info[1])
      call vimext#viewer#LoadByLines(this.asm_viewer)
    else
    endif
  enddef
endclass
