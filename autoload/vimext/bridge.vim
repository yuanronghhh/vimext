vim9script

import "./prompt.vim" as Prompt
import "./logger.vim" as Logger
import "./term.vim" as Term


def BridgeCallback(cmd: string)
  var cmd = self.HandleInput(cmd)
  if cmd is v:null
    return
  endif

  call this.BridgeSend(self, cmd)
enddef

def BridgeInterrupt()
  if pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(bridge_pid)
enddef
