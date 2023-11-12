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

  if has("win32")
    let l:prompt = vimext#prompt#Create(l:dbg, l:proto)
  else
  endif
  call l:dbg.SetConfig(l:dbg, l:prompt, l:proto)

  if exists('#User#DbgDebugStartPre')
    doauto <nomodeline> User DbgDebugStartPre
  endif

  let l:self = {
        \ "proto": l:proto,
        \ "prompt": l:prompt
        \ }
  let s:self = l:self

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

function vimext#runner#Continue() abort
  call s:Call(s:self.proto.Continue, v:null)
endfunction

function vimext#runner#Break(args) abort
  call s:Call(s:self.proto.Break, a:args)
endfunction

function vimext#runner#Clear(args) abort
  call s:Call(s:self.proto.Clear, a:args)
endfunction

function vimext#runner#Delete(args) abort
  call s:Call(s:self.proto.Delete, a:args)
endfunction

function vimext#runner#ParseArgs(args) abort
  let l:info = ["", 0]
  if empty(a:args)
    let l:info[0] = fnameescape(expand('%:p'))
    let l:info[1] = line(".")
  endif

  return l:info
endfunction

function vimext#runner#HandleBreak(msg) abort
  "call sign_define('dbgBreakpoint' .. nr, #{text: strpart(label, 0, 2), texthl: hiName})
endfunction
