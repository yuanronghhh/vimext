let s:gdb_cfg = g:vim_session."/gdb.cfg"
let s:self = v:null

function vimext#runner#Create(lang) abort
  let l:proto = vimext#proto#Create("mi")
  let l:prompt = v:null

  if a:lang == "csharp"
    let l:dbg = vimext#netcoredbg#Create(l:proto)
  else
    let l:dbg = vimext#gdb#Create()
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
        \ "prompt": l:prompt
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

function vimext#runner#Continue(args) abort
  call s:Call(s:self.proto.Continue, a:args)
endfunction

function vimext#runner#Break(args) abort
  let l:info = vimext#runner#ParseFileArgs(a:args)

  call s:Call(s:self.proto.Break, l:info[0] . ":" . l:info[1])
endfunction

function vimext#runner#Clear(args) abort
  call s:Call(s:self.proto.Clear, a:args)
endfunction

function vimext#runner#Delete(args) abort
  call s:Call(s:self.proto.Delete, a:args)
endfunction

function vimext#runner#ParseFileArgs(args) abort
  let l:info = ["", 0]
  if empty(a:args)
    let l:info[0] = fnameescape(expand('%:p'))
    let l:info[1] = line(".")
  endif

  return l:info
endfunction

function s:PromptExit(job, status) abort
  call vimext#logger#Info("PromptExit")

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
  call vimext#logger#Info(l:info)
  if l:info[0] == 1 " quit
    if exists('#User#DbgDebugStopPre')
      doauto <nomodeline> User DbgDebugStopPre
    endif
  endif

  return l:info[1] . " " . l:info[2]
endfunction

function s:PromptOut(channel, msg) abort
  let l:proto = s:self.proto
  let l:prompt = s:self.prompt

  let l:msg = l:proto.ProcessMsg(a:channel, a:msg)
  if l:msg == v:null
    return
  endif

  let l:info = l:proto.DecodeLine(l:msg)

  if info[0] == 1 " hit breakpoint
    call vimext#prompt#LoadSource(l:prompt, info[1], info[2])
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 2 " exit normally
    call vimext#prompt#SetOutputState(l:prompt, 1)

  elseif info[0] == 3 " running
    call vimext#prompt#SetOutputState(l:prompt, 0)

  elseif info[0] == 4 " user set breakpoint
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

  else
    call vimext#prompt#PrintOutput(l:prompt, a:msg)
  endif
endfunction

function vimext#runner#HandleBreak(msg) abort
  "call sign_define('dbgBreakpoint' .. nr, #{text: strpart(label, 0, 2), texthl: hiName})
endfunction
