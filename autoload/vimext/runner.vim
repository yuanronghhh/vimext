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
  call vimext#sign#Init()
  call l:dbg.SetConfig(l:dbg, l:prompt, l:proto)

  let l:self = {
        \ "proto": l:proto,
        \ "prompt": l:prompt,
        \ "dbg": l:dbg
        \ }
  let s:self = l:self

  if exists('#User#DbgDebugStartPre')
    doauto <nomodeline> User DbgDebugStartPre
  endif
  call l:prompt.Start(l:prompt)

  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray

  if exists('#User#DbgDebugStartPost')
    doauto <nomodeline> User DbgDebugStartPost
  endif

  call vimext#runner#Restore()
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

  let s:self = v:null
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
    let l:info[1] = vimext#prompt#GetSouceWinPath(s:self.prompt)

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

function s:PromptOut(channel, msg) abort
  "call vimext#logger#Info(a:msg)
  let l:proto = s:self.proto
  let l:prompt = s:self.prompt

  let l:info = l:proto.ProcessOutput(a:msg)
  if l:info == v:null
    return
  endif

  if info[0] == 1 " hit breakpoint
    call vimext#logger#ProfileStart("vimext#prompt#LoadSource")
    call vimext#prompt#LoadSource(l:prompt, info[2], info[3])
  call vimext#logger#ProfileEnd()

    call vimext#sign#Line(info[2], info[3])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 2 " exit normally
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 3 " running
    call vimext#prompt#SetOutputState(l:prompt, 0)

  elseif info[0] == 4 " user set breakpoint
    "brkid,type,disp,enable,func,file,fullname,line
    call vimext#breakpoint#Add(l:info)
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 5 " exit end stepping range
    call vimext#prompt#LoadSource(l:prompt, info[1], info[2])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 7 " filter useless msg

  elseif info[0] == 8 " output msg
    call vimext#prompt#PrintOutput(l:prompt, info[1])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 9 " entry-point-hit
    call vimext#prompt#LoadSource(l:prompt, info[1], info[2])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 10 " error msg
    call vimext#prompt#PrintOutput(l:prompt, info[1])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 11 " breakpoint delete
    call vimext#breakpoint#DeleteID(l:info[1])

  else
    call vimext#prompt#PrintOutput(l:prompt, l:info[9])
  endif
endfunction
