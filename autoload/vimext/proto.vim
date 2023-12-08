vim9script

import "../vimext.vim" as VimExt

export def ParseInputArgs(cmd: string)
  var nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(nameIdx) <= 2
    return ""
  endif

  return nameIdx[2]
enddef

export def ProcessMsg(text: string)
  var text = v:null

  if text =~ "(gdb)"
        \ || text == ""
        \ || text[0] == "&"
    return v:null
  endif

  return text
enddef

export class MIProto
  this.name = ""
  this.state = 0
  this.lines = []
  this.Break = "-break-insert"
  this.Clear = "-break-delete"
  this.Arguments = "-exec-arguments"
  this.Abort = "-exec-abort"
  this.Run = "-exec-run"
  this.Step = "-exec-step"
  this.Next = "-exec-next"
  this.Finish = "-exec-finish"
  this.Interrupt = "-exec-interrupt"
  this.Continue = "-exec-continue"
  this.Until = "-exec-until"
  this.Eval = "-var-evaluate-expression"
  this.VarCreate = "-var-create"
  this.VarChildren = "-var-list-children"
  this.Frame = "-interpreter-exec mi frame"
  this.Console = "-interpreter-exec console"
  this.Attach = "--attach"
  this.Source = "source"
  this.Set = "-gdb-set"
  this.Exit = "-gdb-exit"
  this.SaveBreakoints = "save breakpoints"
  this.Start = "start"
  this.Disassemble = "disassemble"
  this.Print = "print"

  def new(name: string)
    this.name = name
  enddef

  def GetStart()
    if this.name == "mi"
      return this.Run
    elseif this.name == "mi2"
      return this.Start
    else
      return v:null
    endif
  enddef

  def ProcessInput(cmd: string)
    " type,cmd,args,pre-execute-cmd
    var info = [0, "", "", 0]
    var cmd = "next"

    if cmd != "" && cmd isnot v:null
      var cmd = cmd
      var info[1] = cmd
    endif

    if cmd == "q"
          \ || cmd == "quit"
          \ || cmd == "exit"
      var info[0] = 1
      var info[1] = this.Exit
      var info[2] = ParseInputArgs(cmd)
      return info
    endif

    if cmd == "s"
          \ || cmd == "step"
      var info[0] = 2
      var info[1] = this.Step
      var info[2] = ParseInputArgs(cmd)
      return info
    endif

    if cmd == "fin"
          \ || cmd == "finish"
      var info[0] = 3
      var info[1] = this.Finish
      var info[2] = ParseInputArgs(cmd)
      return info
    endif

    if cmd == "c"
          \ || cmd == "continue"
      var info[0] = 4
      var info[1] = this.Continue
      var info[2] = ParseInputArgs(cmd)
      return info
    endif

    if cmd == "n"
          \ || cmd == "next"
      var info[0] = 4
      var info[1] = this.Next
      var info[2] = ParseInputArgs(cmd)
      return info
    endif

    if cmd == "r"
          \ || cmd == "run"
      var info[0] = 5
      var info[1] = this.Run
      var info[2] = ParseInputArgs(cmd)
      return info
    endif

    if cmd =~ "^b "
          \ || cmd =~ "^break "
      var info[0] = 6
      var info[1] = this.Break
      var info[2] = ParseInputArgs(cmd)

      return info
    endif

    if cmd =~ "^p "
          \ || cmd =~ "^print "
      var args = ParseInputArgs(cmd)

      if this.name == "mi"
        if stridx(args, "*") > -1
          var info[1] = this.VarChildren
          var info[2] = "_innervar"
          var info[3] = this.VarCreate . " _innervar" . "  " . "\"" . substitute(args, "*", "", "g") . "\""
        else
          var info[1] = this.VarCreate
          var info[2] = "_innervar" . "  " . "\"" . args . "\""
        endif
      else
        var info[1] = this.Print
        var info[2] = args
      endif

      var info[0] = 7
      return info
    endif

    return info
  enddef

  def ProcessOutput(msg: string)
    "call vimext#logger#Info(a:msg)
    var msg = ProcessMsg(a:msg)
    if msg is v:null
      return v:null
    endif

    var info = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    if msg =~ '^\*stopped,reason="breakpoint-hit"'
      var nameIdx = matchlist(msg, '^\*stopped,reason="breakpoint-hit",\S*,bkptno="\(\d*\)",\S*,fullname=\([^,]*\),line="\(\d\+\)"')
      if len(nameIdx) == 0
        return info
      endif

      var info[0] = 1
      var info[1] = nameIdx[1]  " breakpoint
      var info[2] = VimExt.DecodeFilePath(nameIdx[2])  " filename
      var info[3] = nameIdx[3]  " lineno
      var info[4] = nameIdx[4]  " col -> this only for netcoredbg

    elseif msg == '*stopped,reason="exited",exit-code="0"'
          \ || msg == '*stopped,reason="exited-normally"'
      var info[0] = 2

    elseif msg =~ '^=breakpoint-deleted,id='
      var nameIdx = matchlist(msg, '=breakpoint-deleted,id="\(\d\+\)"')
      if len(nameIdx) > 0
        var info[0] = 11
        var info[1] = nameIdx[1] " breakpoint id
      endif

    elseif msg =~ '^=breakpoint-created,bkpt'
          \ || msg =~ '^=breakpoint-modified,bkpt'
          \ || msg =~ '^\^done,bkpt=\S*,fullname='

      var nameIdx = matchlist(msg, '^[^,]\+,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)"\S*,func="\([^,]*\)",file="\([^,]*\)",fullname=\([^,]*\),line="\(\d\+\)"')
      if len(nameIdx) > 0
        var info[0] = 4         " user set breakpoint
        var info[1] = nameIdx[1]  " break number
        var info[2] = nameIdx[2]  " type
        var info[3] = nameIdx[3]  " disp
        var info[4] = nameIdx[4] ? "y" : 0  " enable
        var info[5] = nameIdx[5]  " func
        var info[6] = nameIdx[6]  " file
        var info[7] = VimExt.DecodeFilePath(nameIdx[7]) " fullname
        var info[8] = nameIdx[8] " line
      else
        var info[0] = 7
      endif

    elseif msg =~ '^\*stopped,reason="end-stepping-range"'
          \ || msg =~ '^\*stopped,reason="function-finished"'
          \ || msg =~ '\*stopped,reason="signal-received"'

      var nameIdx = matchlist(msg, '^\*stopped,reason=.*,fullname=\([^,]*\),line="\(\d\+\)"')
      if len(nameIdx) > 0
        var info[0] = 5
        var info[1] = VimExt.DecodeFilePath(nameIdx[1])  " filename
        var info[2] = nameIdx[2]  " lineno
        var info[3] = nameIdx[3]  " col -> only for netcoredbg
      endif

    elseif msg =~ '^=thread-selected,'
      var nameIdx = matchlist(msg, '^=thread-selected,.*,fullname=\([^,]\+\),line="\(\d\+\)"')
      if len(nameIdx) > 0
        var info[0] = 5
        var info[1] = VimExt.DecodeFilePath(nameIdx[1])  " filename
        var info[2] = nameIdx[2]  " lineno
        var info[3] = nameIdx[3]  " col -> only for netcoredbg
      endif
    elseif msg =~ '^\^exit'
      var info[0] = 6

    elseif msg =~ '^=message,text='
      var nameIdx = matchlist(msg, '^=message,text=\([^\n]*\),send-to="\([^,]\+"\)')

      if len(nameIdx) > 0
        var info[0] = 8
        var info[1] = VimExt.DecodeMessage(nameIdx[1], v:false)
        var info[2] = nameIdx[2]
      endif

    elseif msg =~ '^\^done,bkpt=\S*,warning='
      var nameIdx = matchlist(msg, '^\^done,bkpt={number="\(\d*\)",type="\([^,]\+\)",disp="\([^,]\+\)",enabled="\(\w\)",warning=\([^}]*\)}')

      if len(nameIdx) > 0
        var info[0] = 9         " user set breakpoint
        var info[1] = VimExt.DecodeMessage(nameIdx[5], v:true) " warning
        var info[2] = nameIdx[1]  " break number
        var info[3] = nameIdx[2]  " type
        var info[4] = nameIdx[3] == "y" ? 1 : 0  " enable
      endif

    elseif msg =~ '^\~"Dump of assembler code for def '
      var nameIdx = matchlist(msg, '^\~"Dump of assembler code for def \([^$]\+\):')

      if len(nameIdx) > 0
        var info[0] = 15
        var info[1] = nameIdx[1]
      endif

      var this.state = 1
      var this.lines = []
    elseif msg =~ '^\~"End of assembler dump.'
      var info[0] = 16
      var info[1] = this.lines
      var this.state = 0

    elseif msg =~ '^\~"=>'
      var nameIdx = matchlist(msg[2:], '^=>\s\+\(\S\+\) <+\(\d\+\)>')
      var msg = VimExt.DecodeMessage(msg[1:], v:false)

      if len(nameIdx) > 0
        var info[0] = 14
        var info[1] = nameIdx[1]
        var info[2] = nameIdx[2]
        var info[3] = substitute(msg, "^=>[ ]*", "", "")
        call add(s:this.lines, info[3])
      endif
    elseif msg[0] == '~'

      if this.state == 1
        var info[0] = 0
        var line = VimExt.DecodeMessage(msg[1:], v:false)
        var line = substitute(line, '^[ ]*', "", "g")
        var line = substitute(line, '^=>[ ]*', "", "g")
        call add(s:this.lines, line)
      else
        var info[0] = 8
        var info[1] = VimExt.DecodeMessage(msg[1:], v:false)
      endif

    elseif msg =~ '^=cmd-param-changed,'
      var nameIdx = matchlist(msg, '^=cmd-param-changed,param="\([^\n]\+\)",value="\([^,]\+\)"')

      if len(nameIdx) > 0
        var info[0] = 8
        var info[1] = nameIdx[1] . " " . nameIdx[2]
      endif

    elseif msg =~ '^\^done,name='
      var nameIdx = matchlist(msg, '^\^done,name="\([^"]*\)",value=\([^,]*\),attributes="\([^"]*\)",exp="\([^"]*\)"')

      if len(nameIdx) > 0
        var info[0] = 8
        var info[1] = nameIdx[4] . " = " . VimExt.DecodeMessage(nameIdx[2], v:false)
      endif

    elseif msg =~ '^\*stopped,reason="entry-point-hit"'
      var nameIdx = matchlist(msg, '^\*stopped,reason="entry-point-hit",.*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
      if len(nameIdx) > 0
        var info[0] = 9
        var info[1] = VimExt.DecodeFilePath(nameIdx[1])  " filename
        var info[2] = nameIdx[2]  " lineno
        var info[3] = nameIdx[3]  " col
        var info[4] = 0  " breakid
      endif

    elseif msg =~ '^\^error,msg='
      var nameIdx = matchlist(msg, '^\^error,msg=\([^$]\+\)')

      if len(nameIdx) > 0
        var info[0] = 10
        var info[1] = VimExt.DecodeMessage(nameIdx[1], v:false)
      endif

    elseif msg =~ '\*stopped,reason="exception-received",'
      var nameIdx = matchlist(msg, '^\*stopped,reason="exception-received",exception-name="\([^"]\+\)",exception="\([^"]\+\)",')
      if len(nameIdx) > 0
        var info[0] = 10
        var info[1] = nameIdx[1] . ": " . VimExt.DecodeMessage('"' . nameIdx[2] . '\"', v:false)
      endif

    elseif msg =~ '^\*stopped,reason="exited",exit-code='
      var nameIdx = matchlist(msg, '^\*stopped,reason="exited"-code="\(\d\+\)"')
      if len(nameIdx) > 0
        var info[0] = 10
        var info[1] = "exit-code: " . nameIdx[1]
      endif
    else
      return v:null
    endif

    return info
  enddef

  def Dispose()
  enddef
endclass
