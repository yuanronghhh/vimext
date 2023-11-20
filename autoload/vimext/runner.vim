let s:gdb_cfg = g:vim_session."/gdb.cfg"
let s:self = v:null

function vimext#runner#Create(lang) abort
  let l:prompt = v:null
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

  if has("win32")
    let l:prompt = vimext#prompt#Create(l:dbg, l:funcs)
  else
  endif

  if l:prompt == v:null
    return v:null
  endif

  call vimext#sign#Init()
  call l:dbg.SetConfig(l:dbg, l:prompt, l:proto)

  let l:self = {
        \ "proto": l:proto,
        \ "prompt": l:prompt,
        \ "dbg": l:dbg,
        \ "asm_win": v:null,
        \ "dbg_win": v:null,
        \ "pc_id": 31,
        \ "asm_id": 32,
        \ "asm_func": v:null,
        \ "output_win": v:null,
        \ "source_win": v:null,
        \ }
  let s:self = l:self
  if exists('#User#DbgDebugStartPre')
    doauto <nomodeline> User DbgDebugStartPre
  endif

  call l:prompt.Start(l:prompt)
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

  let l:prompt = s:self.prompt

  if a:args == v:null
    call l:prompt.Send(l:prompt, a:cmd)
  else
    call l:prompt.Send(l:prompt, a:cmd . " " . a:args)
  endif
endfunction

function vimext#runner#Dispose() abort
  call s:self.prompt.Dispose(s:self.prompt)
  call s:self.proto.Dispose(s:self.proto)
  call s:self.dbg.Dispose(s:self.dbg)

  call vimext#sign#DeInit()
  call vimext#breakpoint#DeInit()

  if s:self.source_win != v:null
    call vimext#buffer#WipeWin(s:self.source_win)
    unlet s:self.source_win
  endif

  if s:self.asm_win != v:null
    call vimext#buffer#WipeWin(s:self.asm_win)
    unlet s:self.asm_win
  endif

  unlet s:self.output_win
  unlet s:self.dbg_win

  let s:self = v:null
endfunction

function vimext#runner#GetSouceWinPath(self) abort
  return vimext#buffer#GetNameByWinID(a:self.source_win)
endfunction

function vimext#runner#Asm() abort
  if vimext#buffer#WinExists(s:self.asm_win)
    return
  endif

  let s:self.asm_win = vimext#runner#CreateAsmWin(s:self)
  call s:Call(s:self.proto.Disassemble, "$pc")
  call win_gotoid(s:self.dbg_win)
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
    let l:info[1] = vimext#runner#GetSouceWinPath(s:self.prompt)

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

function vimext#runner#CreateAsmWin(self)
  let l:win = vimext#buffer#NewWindow("asm", 3, a:self.source_win)

  setlocal nowrap
  setlocal number
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal filetype=asm
  setlocal bufhidden=wipe
  setlocal signcolumn=no
  setlocal modifiable

  return l:win
endfunction

function vimext#runner#LoadAsmBreak(self, msg) abort
  let l:cwin = win_getid()

  call win_gotoid(a:self.asm_win)
  let l:buff = vimext#buffer#GetNameByWinID(a:self.asm_win)

  call append(line('$') - 1, a:msg)
  call vimext#sign#Line(a:self.asm_id, l:buff, line("$") - 1)

  call win_gotoid(l:cwin)
endfunction

function vimext#runner#LoadSource(self, fname, lnum) abort
  let l:cwin = win_getid()
  if !filereadable(a:fname)
    call vimext#logger#Warning("file not readable " . a:fname)
    return
  endif

  if a:self.source_win == v:null
    let a:self.source_win = vimext#buffer#NewWindow("source", 1, v:null)
  endif

  if vimext#buffer#GetNameByWinID(a:self.source_win) != a:fname
    execute "edit ".a:fname
    let a:self.source_buff = bufnr("%")
    setlocal signcolumn=yes
  endif
  call vimext#sign#Line(a:self.pc_id, a:fname, a:lnum)
  call vimext#prompt#SetOutputState(a:self.prompt, 1)

  if a:self.asm_win != v:null
    call s:Call(s:self.proto.Disassemble, "$pc")
  endif

  call win_gotoid(l:cwin)
endfunction

function vimext#runner#PrintOutput(self, msg) abort
  if vimext#prompt#GetOutputState(a:self.prompt) == 2 && a:self.asm_win != v:null
    call vimext#prompt#PrintOutput(a:self.prompt, a:self.asm_win, a:msg)
  else
    call vimext#prompt#PrintOutput(a:self.prompt, a:self.output_win, a:msg)
    call vimext#prompt#SetOutputState(a:self.prompt, 1)
  endif
endfunction

function s:PromptOut(channel, msg) abort
  "call vimext#logger#Info(a:msg)
  let l:proto = s:self.proto
  let l:prompt = s:self.prompt

  let l:info = l:proto.ProcessOutput(a:msg)
  if l:info == v:null
    return
  endif

  if info[0] == 1 " hit breakpoint
    call vimext#runner#LoadSource(s:self, info[2], info[3])

  elseif info[0] == 2 " exit normally
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 3 " running
    call vimext#prompt#SetOutputState(l:prompt, 0)

  elseif info[0] == 4 " user set breakpoint
    "brkid,type,disp,enable,func,file,fullname,line
    call vimext#breakpoint#Add(l:info)
    call vimext#prompt#SetOutputState(l:prompt, 1)

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

  elseif info[0] == 12 " disassemble
    "Dump of assembler code for function main:
    call vimext#prompt#SetOutputState(l:prompt, 2)

  elseif info[0] == 13 " done
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 14 " asm break
    call vimext#runner#LoadAsmBreak(s:self, l:info[9])

  elseif info[0] == 15 " asm func info
    if s:self.asm_func != l:info[1]
      call vimext#buffer#ClearWin(s:self.asm_win)
    endif
    call vimext#runner#PrintOutput(s:self, l:info[9])
  else
    call vimext#runner#PrintOutput(s:self, l:info[9])

  endif
endfunction
