let s:break_id = 32
let s:breakpoints = []
let s:gdb_cfg = g:vim_session."/gdb.cfg"


function vimext#breakpoint#Init()
  if !filereadable(s:gdb_cfg)
    call writefile([], s:gdb_cfg, "w")
    call vimext#breakpoint#CreateOne("Main")
    call vimext#breakpoint#CreateOne("main")
  else
    call vimext#prompt#SendCmd("source ".s:gdb_cfg)
  endif

  command -nargs=? Break call vimext#breakpoint#Break(<q-args>)
  command -nargs=? Clear call vimext#breakpoint#Clear(<q-args>)

  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction

function vimext#breakpoint#DeInit()
  let l:cmd = "save breakpoint ".s:gdb_cfg
  call vimext#prompt#SendCmd(l:cmd)

  delcommand Break
  delcommand Clear

  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction

function vimext#breakpoint#Insert(bnum, enabled) abort
endfunction

function s:GetList() abort
endfunction

function vimext#breakpoint#HasBreak(fname, lnum) abort
  return 1
endfunction

function vimext#breakpoint#Togggle(fname, lnum) abort
  if s:HasBreak(filenane, lnum) == 0
    call s:Clear(a:fname, a:lnum)
  else
    call s:Create(a:fname, a:lnum)
  endif
endfunction

function s:ParseArgs(args) abort
  let l:info = ["", 0]
  if empty(a:args)
    let l:info[0] = fnameescape(expand('%:p'))
    let l:info[1] = line(".")
  endif

  return l:info
endfunction

function vimext#breakpoint#Break(args) abort
  let l:info = s:ParseArgs(a:args)
  if l:info == v:null
    return
  endif

  if vimext#breakpoint#HasBreak(l:info[0], l:info[1])
    call vimext#breakpoint#Clear(l:info[0].":".l:info[1])
  else
    call vimext#breakpoint#CreateOne(a:args)
  endif
endfunction

function vimext#breakpoint#CreateOne(msg) abort
  call vimext#prompt#SendCmd("break ".a:msg)
endfunction

function vimext#breakpoint#Create(fname, lnum) abort
  call sign_define('dbgBreakpoint' .. nr, #{text: strpart(label, 0, 2), texthl: hiName})
endfunction

function vimext#breakpoint#Clear(fname, lnum) abort
  call vimext#prompt#SendCmd("clear ".l:fname." ".a:lnum)
endfunction

function s:Delete() abort
endfunction
