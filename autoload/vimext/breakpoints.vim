let s:break_id = 32
let s:brks = []
let s:gdb_cfg = g:vim_session."/gdb.cfg"


function vimext#breakpoints#Init()
  if !filereadable(s:gdb_cfg)
    call writefile([], s:gdb_cfg, "w")
    call vimext#breakpoints#CreateOne("Main")
    call vimext#breakpoints#CreateOne("main")
  else
    call vimext#prompt#SendCmd("source ".s:gdb_cfg)
  endif

endfunction

function vimext#breakpoints#DeInit()
  let l:cmd = "save breakpoints ".s:gdb_cfg
  call vimext#prompt#SendCmd(l:cmd)
endfunction

function s:GetList() abort
endfunction

function vimext#breakpoints#HasBreaks(fname, lnum) abort
  return 1
endfunction

function vimext#breakpoints#Togggle(fname, lnum) abort
  if s:HasBreaks(filenane, lnum) == 0
    call s:Clear(a:fname, a:lnum)
  else
    call s:Create(a:fname, a:lnum)
  endif
endfunction

function vimext#breakpoints#CreateOne(msg) abort
  call vimext#prompt#SendCmd("break ". a:msg)
endfunction

function vimext#breakpoints#Create(fname, lnum) abort
  call sign_define('dbgBreakpoint' .. nr, #{text: strpart(label, 0, 2), texthl: hiName})
endfunction

function vimext#breakpoints#Clear(fname, lnum) abort
  call vimext#prompt#SendCmd("clear ".l:fname." ".a:lnum)
endfunction

function s:Delete() abort
endfunction
