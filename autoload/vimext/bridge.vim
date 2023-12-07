vim9script
var self = v:null

import "./prompt.vim" as Prompt
import "./logger.vim" as Logger
import "./term.vim" as Term

# bridge
def BridgeCallback(cmd: string)
  var cmd = self.HandleInput(cmd)
  if cmd is v:null
    return
  endif

  call BridgeSend(self, cmd)
enddef

def BridgeInterrupt()
  if pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(bridge_pid)
enddef

def Ref()
  return self
enddef

def Create(dbg: any, funcs: dict)
  var self = v:null
  if has("win32")
    var self = Prompt.Create(funcs)
  else
    var self = Term.Create(funcs)
  endif

  if self is v:null
    return v:null
  endif

  if !has('terminal')
    call Logger.Error("+terminal not enabled in vim")
    return v:null
  endif

  return self
enddef

def Dispose()
enddef
