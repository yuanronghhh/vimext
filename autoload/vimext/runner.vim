let s:gdb_cfg = g:vim_session."/gdb.cfg"
let s:self = v:null
let s:output_state = 1


function vimext#runner#Create(lang) abort
  let l:bridge = v:null
  let l:proto = v:null

  if s:self != v:null
    call vimext#logger#Warning("call not start two debugger")
    return v:null
  endif

  if a:lang == "csharp"
    let l:proto = vimext#proto#Create("mi")
    let l:dbg = vimext#netcoredbg#Create(l:proto)
  elseif a:lang == "c"
    let l:proto = vimext#proto#Create("mi2")
    let l:dbg = vimext#gccdbg#Create(l:proto)
  else
    return v:null
  endif

  let l:funcs = {
        \ 'HandleExit': function("s:PromptExit"),
        \ "HandleInput": function("s:PromptInput"),
        \ 'HandleOutput': function("s:PromptOut")
        \ }

  let l:bridge = vimext#bridge#Create(l:dbg, l:funcs)
  if l:bridge == v:null
    return v:null
  endif

  call vimext#sign#Init()
  call l:dbg.SetConfig(l:dbg, l:bridge, l:proto)

  let l:self = {
        \ "proto": l:proto,
        \ "bridge": l:bridge,
        \ "dbg": l:dbg,
        \ "dbg_win": v:null,
        \ "output_win": v:null,
        \ "source_viewer": v:null,
        \ "asm_viewer": v:null
        \ }
  let s:self = l:self
  if exists('#User#DbgDebugStartPre')
    doauto <nomodeline> User DbgDebugStartPre
  endif

  call l:bridge.Start(l:bridge)
  let l:self.dbg_win = win_getid()
  let l:self.output_win = l:self.dbg_win

  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray

  call vimext#runner#Restore()

  if exists('#User#DbgDebugStartPost')
    doauto <nomodeline> User DbgDebugStartPost
  endif

  return l:self
endfunction

function s:Call(cmd, args) abort
  if s:self == v:null
    return
  endif

  let l:bridge = s:self.bridge

  if a:args == v:null
    call l:bridge.Send(l:bridge, a:cmd)
  else
    call l:bridge.Send(l:bridge, a:cmd . " " . a:args)
  endif
endfunction

function vimext#runner#Dispose() abort
  call s:self.bridge.Dispose(s:self.bridge)
  call s:self.proto.Dispose(s:self.proto)
  call s:self.dbg.Dispose(s:self.dbg)

  call vimext#sign#DeInit()
  call vimext#breakpoint#DeInit()

  if s:self.source_viewer != v:null
    call s:self.source_viewer.Dispose(s:self.source_viewer)
    unlet s:self.source_viewer
  endif

  if s:self.asm_viewer != v:null
    call s:self.asm_viewer.Dispose(s:self.asm_viewer)
    unlet s:self.asm_viewer
  endif

  unlet s:self.output_win
  unlet s:self.dbg_win

  let s:self = v:null
endfunction

function vimext#runner#GetSouceWinPath(self) abort
  let l:winid = vimext#viewer#GetWinID(a:self.source_viewer)
  return vimext#buffer#GetNameByWinID(l:winid)
endfunction

function vimext#runner#Asm() abort
  if s:self.proto.name == "mi2" && s:self.dbg.name == "gdb"
  else
    return
  endif


  if s:self.asm_viewer != v:null
    call vimext#viewer#Show(s:self.asm_viewer)
    return
  endif
  let l:source_win = vimext#viewer#GetWinID(s:self.source_viewer)
  let s:self.asm_viewer = vimext#runner#CreateAsmViewer(l:source_win)

  call win_gotoid(s:self.dbg_win)
  call s:Call(s:self.proto.Disassemble, "$pc")
endfunction

function vimext#runner#Run(args) abort
  if a:args != v:null && a:args != ""
    if s:self.dbg.name == "gdb"
      call s:Call("file", a:args)
    else
      call s:Call(s:self.proto.Arguments, a:args)
    endif
  endif
  let l:start = vimext#proto#GetStart(s:self.proto)

  if l:start == v:null
    return
  endif

  call s:Call(l:start, "")
endfunction

function vimext#runner#Attach(pid) abort
  call s:Call(s:self.proto.Attach, a:pid)
endfunction

function vimext#runner#Restore() abort
  if !filereadable(s:gdb_cfg)
    call writefile([], s:gdb_cfg, "w")
  else
    if s:self.proto.name == "mi"
    else
      call s:Call(s:self.proto.SaveBreakoints, s:gdb_cfg)
    endif
  endif
endfunction

function vimext#runner#Next() abort
  call s:Call(s:self.proto.Next, v:null)
endfunction

function vimext#runner#Stop() abort
  call s:Call(s:self.proto.Stop, v:null)
endfunction

function vimext#runner#Step() abort
  call s:Call(s:self.proto.Step, v:null)
endfunction

function vimext#runner#Continue() abort
  call s:Call(s:self.proto.Continue, v:null)
endfunction

function vimext#runner#Break(args) abort
  let l:info = vimext#breakpoint#Parse(a:args)
  if l:info == v:null
    return
  endif

  if l:info[0] == 1
    let l:info[1] = vimext#runner#GetSouceWinPath(s:self)

    let l:brk = vimext#breakpoint#Get(l:info[1], l:info[2])
    if l:brk != v:null
      call vimext#breakpoint#Delete(l:brk)
      call s:Call(s:self.proto.Clear, l:brk[1])
    else
      call s:DeleteBreakPointByFName(s:self, l:info[1], l:info[2])
    endif
  else
    call s:Call(s:self.proto.Break, l:info[1])
  endif
endfunction

function vimext#runner#Clear(args) abort
  call s:Call(s:self.proto.Clear, a:args)
endfunction

function vimext#runner#Delete() abort
  call s:Call(s:self.proto.Delete, v:null)
endfunction

function s:PromptExit(job, status) abort
  if exists('#User#DbgDebugStopPost')
    doauto <nomodeline> User DbgDebugStopPost
  endif
endfunction

function s:PromptInput(cmd) abort
  let l:info = s:self.proto.ProcessInput(s:self.proto, a:cmd)

  if l:info[0] == 1 " quit
    if exists('#User#DbgDebugStopPre')
      doauto <nomodeline> User DbgDebugStopPre
    endif
  endif

  if l:info[0] == 6
    call vimext#runner#Break(l:info[2])
    return v:null
  endif

  if l:info[0] == 7 " print
    if l:info[3] != 0
      call s:Call(l:info[3], v:null)
    endif
  endif

  return l:info[1] . " " . l:info[2]
endfunction

function s:DeleteBreakPointByFName(self, fname, lnum) abort
  let l:brk = vimext#breakpoint#Get(a:fname, a:lnum)
  if l:brk == v:null
    call s:Call(a:self.proto.Break, a:fname . ":" . a:lnum)
  else
    call vimext#breakpoint#Delete(l:brk)
  endif
endfunction

function vimext#runner#CreateAsmViewer(basewin) abort
  let l:viewer = vimext#viewer#CreateTextMode("asm", 3, a:basewin, 32)
  let l:winid = vimext#viewer#GetWinID(l:viewer)

  call win_gotoid(l:winid)
  setlocal nowrap
  setlocal number
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal filetype=asm
  setlocal bufhidden=wipe
  setlocal signcolumn=no
  setlocal modifiable

  return l:viewer
endfunction

function vimext#runner#LoadSource(self, fname, lnum) abort
  if a:self.source_viewer == v:null
    let a:self.source_viewer = vimext#viewer#CreateFileMode("source", 1, a:self.dbg_win, 31)
  endif
  call vimext#viewer#LoadByFile(a:self.source_viewer, a:fname, a:lnum)

  if vimext#viewer#IsShow(a:self.asm_viewer)
    call s:Call(s:self.proto.Disassemble, "$pc")
  endif
endfunction

function vimext#runner#PrintOutput(self, msg) abort
  call vimext#bridge#PrintOutput(a:self.bridge, a:self.output_win, a:msg)
endfunction

function s:PromptOut(channel, msg) abort
  let l:proto = s:self.proto
  let l:bridge = s:self.bridge

  let l:info = l:proto.ProcessOutput(a:msg)
  if l:info == v:null
    return
  endif

  if info[0] == 1 " hit breakpoint
    call vimext#runner#LoadSource(s:self, info[2], info[3])

  elseif info[0] == 2 " exit normally

  elseif info[0] == 3 " running

  elseif info[0] == 4 " user set breakpoint
    "brkid,type,disp,enable,func,file,fullname,line
    call vimext#breakpoint#Add(l:info)

  elseif info[0] == 5 " exit end stepping range
    call vimext#runner#LoadSource(s:self, info[1], info[2])

  elseif info[0] == 7 " filter useless msg

  elseif info[0] == 8 " output msg
    call vimext#runner#PrintOutput(s:self, info[1])

  elseif info[0] == 9 " entry-point-hit
    call vimext#runner#LoadSource(s:self, info[1], info[2])

  elseif info[0] == 10 " error msg
    call vimext#runner#PrintOutput(s:self, info[1])

  elseif info[0] == 11 " breakpoint delete
    call vimext#breakpoint#DeleteID(l:info[1])

  elseif info[0] == 14 " asm break
    call vimext#viewer#SetSignText(s:self.asm_viewer, l:info[1])
    call vimext#viewer#AddLine(s:self.asm_viewer, l:info[3])

  elseif info[0] == 15 " asm start
    call vimext#viewer#SetUniqueID(s:self.asm_viewer, l:info[1])
    call vimext#viewer#AddLine(s:self.asm_viewer, l:info[1] . ":")

    let s:output_state = 2
  elseif info[0] == 16 " asm end
    call vimext#viewer#LoadByLines(s:self.asm_viewer)
    let s:output_state = 1
  else
    if s:output_state == 2
      let l:line = substitute(l:info[9], "^[ ]*", "", "g")
      call vimext#viewer#AddLine(s:self.asm_viewer, l:line)

    else
      call vimext#runner#PrintOutput(s:self, l:info[9])
      let s:output_state = 1
    endif
  endif
endfunction
