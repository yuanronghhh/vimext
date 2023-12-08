vim9script

export class NetCoreDbg
  this.proto: any = v:null
  this.name = "netcoredbg"

  def new(proto: any)
    this.proto = proto
    this.name = "netcoredbg"
  enddef

  def SetConfig(prompt: any, proto: any)
    call prompt.Send(prompt, proto.Set . " " . "just-my-code 1")
  enddef

  def GetCmd(param: any)
    var cmd = ["netcoredbg"]
    cmd += ["--interpreter=" . self.proto.name]
    cmd += ["--", "dotnet"]
    return cmd
  enddef

  def Dispose()
  enddef
endclass
