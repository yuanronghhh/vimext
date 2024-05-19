let s:gdb_cfg = g:vim_session."/gdb.cfg"
let s:self = v:null
let s:balloon_multiline = has("balloon_multiline")
let s:balloon_eval_term = has("balloon_eval_term")

function vimext#runner#Create(lang, args) abort
  let bridge = v:null
  let proto = v:null

  if s:self isnot v:null
    :call vimext#logger#Warning("Can not start two debugger")
    return v:null
  endif

  if a:lang == "csharp"
    let proto = vimext#proto#Create("mi")
    let dbg = vimext#netcoredbg#Create(proto)
  elseif a:lang == "c"
    let proto = vimext#proto#Create("mi2")
    let dbg = vimext#gccdbg#Create(proto)
  else
    return v:null
  endif

  if dbg is v:null || proto is v:null
    return v:null
  endif

  let funcs = {
        \ 'HandleExit': function("s:PromptExit"),
        \ "HandleInput": function("s:PromptInput"),
        \ 'HandleOutput': function("s:PromptOut")
        \ }

  :call vimext#sign#Init()

  let self = {
        \ "proto": proto,
        \ "bridge": v:null,
        \ "dbg": dbg,
        \ "dbg_term": v:null,
        \ "cmd_term": v:null,
        \ "source_viewer": v:null,
        \ "asm_viewer": v:null
        \ }
  let s:self = self

  if exists('#User#DbgDebugStartPre')
    doauto <nomodeline> User DbgDebugStartPre
  endif
  let empty_win = win_getid()

  let bridge = vimext#bridge#Create(dbg, funcs)
  let self.bridge = bridge

  let cmd_term = bridge.NewProg()
  if cmd_term is v:null
    :call vimext#logger#Warning("create cmd_term failed")
    return v:null
  endif
  let self.cmd_term = cmd_term

  :call win_execute(empty_win, "close")

  let cmd = dbg.GetCmd(self.dbg, cmd_term, a:args)
  let dbg_term = bridge.NewDbg(bridge, cmd)
  if dbg_term is v:null
    :call vimext#logger#Warning("create dbg_term failed: " .. join(cmd, " "))
    return v:null
  endif

  let self.dbg_term = dbg_term

  :call dbg.SetConfig(dbg, dbg_term, proto)
  :call vimext#breakpoint#Init()

  if exists('#User#DbgDebugStartPost')
    doauto <nomodeline> User DbgDebugStartPost
  endif

  :call vimext#runner#EnableBalloon(self)

  augroup DbgDebug
    autocmd SwapExists * echohl WarningMsg
          \ | echo 'Warning: file is being edited elsewhere'
          \ | echohl None
          \ | let v:swapchoice = 'o'
  augroup END

  return self
endfunction

function vimext#runner#RunCmds(self, cmds) abort
  for cmd in a:cmds
    :call s:Call(cmd[0], cmd[1])
  endfor
endfunction

function vimext#runner#Eval(self, expr, isballon) abort
  let cmds = vimext#proto#ProcessExpr(s:self.proto, a:expr, a:isballon)

  if s:self.dbg.name == "netcoredbg"

    call vimext#runner#RunCmds(s:self, cmds)
  else
    :call s:Call(s:self.proto.DataEvaluate, '"' .. a:expr .. '"')
  endif
endfunction

function vimext#runner#BalloonExpr() abort
  :call vimext#runner#Eval(s:self, v:beval_text, v:true)
  return ""
endfunction

function vimext#runner#EnableBalloon(self) abort
  if has("balloon_eval") || has("balloon_eval_term")
    set balloonexpr=vimext#runner#BalloonExpr()
  endif

  if has("balloon_eval")
    set ballooneval
  endif
  if has("balloon_eval_term")
    set balloonevalterm
  endif

endfunction

function vimext#runner#DisableBalloon(self) abort
  if has("balloon_eval") || has("balloon_eval_term")
    set balloonexpr=
  endif

  if has("balloon_eval")
    set noballooneval
  endif
  if has("balloon_eval_term")
    set noballoonevalterm
  endif
endfunction

function s:Call(cmd, argsstr) abort
  if s:self is v:null
    return
  endif

  let term = s:self.dbg_term

  if a:argsstr is v:null
    :call term.Send(term, a:cmd)
  else
    :call term.Send(term, a:cmd . " " . a:argsstr)
  endif
endfunction

function vimext#runner#Dispose() abort
  :call s:self.bridge.Dispose(s:self.bridge)
  :call s:self.proto.Dispose(s:self.proto)
  :call s:self.dbg.Dispose(s:self.dbg)

  :call vimext#viewer#Go(s:self.source_viewer)
  :call vimext#sign#DeInit()
  :call vimext#breakpoint#DeInit()

  if s:self.source_viewer isnot v:null
    :call s:self.source_viewer.Dispose(s:self.source_viewer)
    unlet s:self.source_viewer
  endif

  if s:self.asm_viewer isnot v:null
    :call s:self.asm_viewer.Dispose(s:self.asm_viewer)
    unlet s:self.asm_viewer
  endif

  :call s:self.cmd_term.Destroy(s:self.cmd_term)
  :call s:self.dbg_term.Destroy(s:self.dbg_term)
  :call vimext#runner#DisableBalloon(s:self)

  augroup DbgDebug
    autocmd! SwapExists
  augroup END

  let s:self = v:null
endfunction

function vimext#runner#GetSouceWinPath(self) abort
  let winid = vimext#viewer#GetWinID(a:self.source_viewer)
  return vimext#buffer#GetNameByWinID(winid)
endfunction

function vimext#runner#GetSouceName(self) abort
  let buff = vimext#viewer#GetBuff(a:self.source_viewer)
  return fnamemodify(buff, ":t")
endfunction

function vimext#runner#Asm() abort
  if s:self is v:null
        \ || s:self.proto is v:null
        \ || s:self.dbg is v:null
    return
  endif

  if s:self.proto.name == "mi2" && s:self.dbg.name == "gdb"
  else
    return
  endif

  if s:self.asm_viewer isnot v:null
    :call vimext#viewer#Show(s:self.asm_viewer)
    :call vimext#runner#SetAsmEnv(s:self.asm_viewer)
  else
    let source_win = vimext#viewer#GetWinID(s:self.source_viewer)
    let asm_viewer = vimext#runner#CreateAsmViewer(v:null)
    let s:self.asm_viewer = asm_viewer
  endif

  :call s:Call(s:self.proto.Disassemble, "$pc")
endfunction

function vimext#runner#Source() abort
  if s:self.source_viewer is v:null
    return
  endif

  :call vimext#viewer#Show(s:self.source_viewer)
endfunction

function vimext#runner#ReRun() abort
  :call s:Call(s:self.proto.Run, v:null)
endfunction

function vimext#runner#Run(args) abort
  let start = vimext#proto#GetStart(s:self.proto)
  if start is v:null
    return
  endif

  if a:args isnot v:null
    if s:self.dbg.name == "gdb"
      :call vimext#runner#Restore()
      " :call s:Call(s:self.proto.Start, v:null)
    elseif s:self.dbg.name == "netcoredbg"
      "let argsstr = join(a:args, " ")
      ":call s:Call(s:self.proto.Arguments, argsstr)
      :call s:Call(s:self.proto.Run, v:null)
    endif
  endif
endfunction

function vimext#runner#Attach(pid) abort
  :call s:Call(s:self.proto.Attach, a:pid)
endfunction

function vimext#runner#Restore() abort
  if !filereadable(s:gdb_cfg)
    :call writefile([], s:gdb_cfg, "w")
  else
    if s:self.proto.name == "mi"
    else
      :call s:Call(s:self.proto.Source, s:gdb_cfg)
    endif
  endif
endfunction

function vimext#runner#Next() abort
  :call s:Call(s:self.proto.Next, v:null)
endfunction

function vimext#runner#Stop() abort
  :call s:Call(s:self.proto.Stop, v:null)
endfunction

function vimext#runner#Step() abort
  :call s:Call(s:self.proto.Step, v:null)
endfunction

function vimext#runner#Finish() abort
  :call s:Call(s:self.proto.Finish, v:null)
endfunction

function vimext#runner#Continue() abort
  :call s:Call(s:self.proto.Continue, v:null)
endfunction

function vimext#runner#Break(args) abort
  let info = vimext#breakpoint#Parse(a:args)
  if info is v:null
    return
  endif
  let cmds = []

  if info[0] == 1
    let brk = vimext#breakpoint#Get(info[1], info[2])

    if s:self.dbg.name == "netcoredbg"
      let info[1] = substitute(info[1], "/", "\\", "g")
    endif

    if brk isnot v:null
      :call vimext#breakpoint#Delete(brk)
      :call add(cmds, [s:self.proto.Clear, brk[1]])
    else
      :call add(cmds, [s:self.proto.Break, info[1] .. ":" .. info[2]])
    endif
  else
    :call add(cmds, [s:self.proto.Break, info[1]])
  endif

  :call vimext#runner#RunCmds(s:self, cmds)
  :call vimext#runner#SaveBrks(s:self)
endfunction

function vimext#runner#Clear(args) abort
  :call s:Call(s:self.proto.Clear, a:args)
endfunction

function vimext#runner#Delete() abort
  :call s:Call(s:self.proto.Delete, v:null)
endfunction

function s:PromptExit(job, status) abort
  if exists('#User#DbgDebugStopPost')
    doauto <nomodeline> User DbgDebugStopPost
  endif
endfunction

function s:PromptInput(cmdstr) abort
  let cmds = s:self.proto.ProcessInput(s:self.proto, a:cmdstr)

  :call vimext#logger#Debug(cmds)

  for cmd in cmds
    if cmd[0] == s:self.proto.Exit
      if exists('#User#DbgDebugStopPre')
        doauto <nomodeline> User DbgDebugStopPre
      endif
    endif

    if cmd[0] == s:self.proto.Break
      :call vimext#runner#Break(cmd[1])
      return v:null
    endif
  endfor
  let cmds = filter(cmds, "v:val[0] != s:self.proto.Break")

  :call vimext#runner#RunCmds(s:self, cmds)
endfunction

function s:DeleteBreakPointByFName(self, fname, lnum) abort
  let brk = vimext#breakpoint#Get(a:fname, a:lnum)
  if brk is v:null
    :call s:Call(a:self.proto.Break, a:fname . ":" . a:lnum)
  else
    :call vimext#breakpoint#Delete(brk)
  endif
endfunction

function vimext#runner#SetAsmEnv(viewer) abort
  :call vimext#viewer#Go(a:viewer)
  :setlocal nowrap
  :setlocal number
  :setlocal noswapfile
  :setlocal buftype=nofile
  :setlocal filetype=asm
  :setlocal bufhidden=wipe
  :setlocal signcolumn=no
  :setlocal modifiable
  :setlocal nolist
endfunction

function vimext#runner#CreateAsmViewer(basewin) abort
  let viewer = vimext#viewer#CreateTextMode("asm", 3, a:basewin, 32)
  :call vimext#runner#SetAsmEnv(viewer)
  return viewer
endfunction

function vimext#runner#LoadSource(self, fname, lnum) abort
  if a:self.source_viewer is v:null
    let dbg_win = a:self.dbg_term.GetWinID(a:self.dbg_term)

    let a:self.source_viewer = vimext#viewer#CreateFileMode("source", 1, dbg_win, 31)
    :call vimext#viewer#Go(a:self.source_viewer)
    :execute "wincmd H"

    :call vimext#viewer#LoadByFile(a:self.source_viewer, a:fname, a:lnum)
  else
    :call vimext#viewer#Show(s:self.source_viewer)
    :call vimext#viewer#LoadByFile(a:self.source_viewer, a:fname, a:lnum)
  endif

  if vimext#viewer#IsShow(a:self.asm_viewer)
    :call s:Call(s:self.proto.Disassemble, "$pc")
  endif
endfunction

function vimext#runner#ShowBalloon(self, amsg) abort
  if s:balloon_eval_term
    let msg = balloon_split(a:amsg)

    :call balloon_show(msg)
  else
    :call balloon_show(a:amsg)
  endif
endfunction

function vimext#runner#PrintOutput(self, msgs) abort
  let term = a:self.cmd_term

  :call term.Print(term, a:msgs)
endfunction

function vimext#runner#SaveBrks(self) abort
  if a:self.dbg.name == "gdb"
    :call s:Call(a:self.proto.SaveBreakoints, s:gdb_cfg)
  endif
endfunction

function vimext#runner#PrintError(self, msgs) abort
  let term = a:self.cmd_term
  :call term.Print(term, a:msgs)
endfunction

function s:PromptOut(channel, msg) abort
  if s:self is v:null
    return
  endif

  let proto = s:self.proto

  let info = proto.ProcessOutput(a:msg)
  if info is v:null
    return
  endif
  let asm_viewer = s:self.asm_viewer

  :call vimext#logger#Debug(info)

  if info[0] == 1 " hit breakpoint
    :call vimext#runner#LoadSource(s:self, info[2], info[3])

  elseif info[0] == 3 " print expr value
    :call vimext#runner#ShowBalloon(s:self, info[1])

  elseif info[0] == 4 " user set breakpoint
    "brkid,type,disp,enable,func,file,fullname,line
    :call vimext#breakpoint#Add(info[0:8])

  elseif info[0] == 5 " stopped end stepping range
    :call vimext#runner#LoadSource(s:self, info[1], info[2])

  elseif info[0] == 8 " message
    :call vimext#runner#PrintOutput(s:self, info[1])

  elseif info[0] == 9 " entry-point-hit
    :call vimext#runner#LoadSource(s:self, info[1], info[2])

  elseif info[0] == 10 " error msg
    :call vimext#runner#PrintError(s:self, info[1])

  elseif info[0] == 11 " breakpoint delete
    :call vimext#breakpoint#DeleteID(info[1])

  elseif info[0] == 14 " asm break
    :call vimext#viewer#SetSignText(asm_viewer, info[1])

  elseif info[0] == 15 " asm start
    :call vimext#viewer#SetUniqueID(asm_viewer, info[1])

  elseif info[0] == 16 " asm end
    :call vimext#viewer#SetLines(asm_viewer, info[1])
    :call vimext#viewer#LoadByLines(asm_viewer)
  else " info[0] == 7
  endif
endfunction
