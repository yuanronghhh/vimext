let s:gdb_cfg = g:vim_session."/gdb.cfg"
let s:self = v:null

function vimext#runner#Create(lang) abort
  let l:prompt = v:null
  let l:proto = v:null

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

  call l:dbg.SetConfig(l:dbg, l:prompt, l:proto)

  let l:self = {
        \ "proto": l:proto,
        \ "prompt": l:prompt,
        \ "breaks": {}
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
  unlet s:self
endfunction

function vimext#runner#Run(args) abort
  if a:args != v:null && a:args != ""
    call s:Call(s:self.proto.Arguments, a:args)
  endif

  call s:Call(s:self.proto.Run, "")
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
  let l:info = s:BreakPointParse(s:self, a:args)
  if l:info == v:null
    return
  endif

  if l:info[0] == 1
    let l:brk = s:BreakPointGet(s:self, l:info[1], l:info[2])
    if l:brk != v:null
      call s:BreakPointDelete(s:self, l:brk)
    else
      call s:BreakPointDeleteByFName(s:self, l:info[1], l:info[2])
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
  call s:self.prompt.Dispose(s:self.prompt)
  call s:self.proto.Dispose(s:self.proto)

  unlet s:self.prompt
  unlet s:self.proto

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

  if l:info[0] == 7
    if l:info[3] != 0
      call s:Call(l:info[3], v:null)
    endif
  endif

  return l:info[1] . " " . l:info[2]
endfunction

function s:BreakPointParse(self, args)
  if a:args == v:null
    return v:null
  endif

  let l:info = [0, 0, 0]
  " type=1,lnum,fname
  " type=2,func_name

  let l:nameIdx = matchlist(a:args, '^\([^:]\+\):\(\d\+\)$')
  if len(l:nameIdx) > 0
    let l:info[0] = 1
    let l:info[1] = vimext#debug#DecodeMessage('"' . l:nameIdx[1] . '"')
    let l:info[2] = l:nameIdx[2]

    return l:info
  endif

  if a:args =~ '^\(\d\+\)$'
    let l:info[0] = 1
    let l:info[1] = vimext#prompt#GetSourcePath(a:self.prompt)
    let l:info[2] = a:args
    return l:info
  endif

  if a:args =~ '^\(\w\+\)'
    let l:info[0] = 2
    let l:info[1] = a:args
    return l:info
  endif

  return v:null
endfunction

function s:BreakPointDeleteByFName(self, fname, lnum)
  let l:brk = s:BreakPointGet(a:self, a:fname, a:lnum)
  if l:brk == v:null
    call s:Call(a:self.proto.Break, a:fname . ":" . a:lnum)
  else
    call s:BreakPointDelete(a:self, l:brk)
  endif
endfunction

function s:BreakPointDelete(self, brk)
  if a:brk == v:null
    return
  endif

  if !has_key(a:self.breaks, a:brk[1])
    return
  endif

  call remove(a:self.breaks, a:brk[1])
  call s:Call(a:self.proto.Clear, a:brk[1])
  call vimext#prompt#RemoveSign(a:self.prompt, a:brk[7], a:brk[1])
endfunction

function s:BreakPointGet(self, fname, lnum)
  for l:brk in values(a:self.breaks)
    if l:brk[7] == a:fname && l:brk[8] == a:lnum
      return l:brk
    endif
  endfor

  return v:null
endfunction

function s:BreakPointAdd(self, info)
  if a:info[0] != 4
    call vimext#logger#Warning("break info not correct")
    return
  endif

  let l:bid = a:info[1]
  call vimext#prompt#PlaceSign(a:self.prompt,
        \ a:info[7],
        \ a:info[8],
        \ l:bid,
        \ a:info[1],
        \ 1)
  let a:self.breaks[a:info[1]] = a:info
endfunction

function s:PromptOut(channel, msg) abort
  let l:proto = s:self.proto
  let l:prompt = s:self.prompt

  let l:info = l:proto.ProcessOutput(a:msg)
  if l:info == v:null
    return
  endif

  if info[0] == 1 " hit breakpoint
    call vimext#prompt#LoadSource(l:prompt, info[2], info[3])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 2 " exit normally
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 3 " running
    call vimext#prompt#SetOutputState(l:prompt, 0)

  elseif info[0] == 4 " user set breakpoint
    call s:BreakPointAdd(s:self, l:info)
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

  else
    call vimext#prompt#PrintOutput(l:prompt, a:msg)
  endif
endfunction
