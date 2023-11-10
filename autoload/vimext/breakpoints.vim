let s:break_id = 32

let s:brks = []


function vimext#breakpoints#Init()
  let s:iface = {
        \ "Toggle": function("vimext#breakpoints#Togggle"),
        \ "Create": function("vimext#breakpoints#Create"),
        \ "Clear": function("vimext#breakpoints#Clear"),
        \ "Delete": function("vimext#breakpoints#Delete"),
        \ "GetList": function("vimext#breakpoints#GetList")
        \ }
endfunction

function vimext#breakpoints#GetList() abort
endfunction

function vimext#breakpoints#HasBreaks(fname, lnum) abort
  return 1
endfunction

function vimext#breakpoints#Togggle(fname, lnum) abort
  if vimext#breakpoints#HasBreaks(filenane, lnum) == 0
    call vimext#breakpoints#Clear(a:fname, a:lnum)
  else
    call vimext#breakpoints#Create(a:fname, a:lnum)
  endif
endfunction

function vimext#breakpoints#CreateByVar(msg) abort
  call vimext#prompt#PromptSend("break". a:msg)
endfunction

function vimext#breakpoints#Create(fname, lnum) abort
  call sign_define('debugBreakpoint' .. nr, #{text: strpart(label, 0, 2), texthl: hiName})
endfunction

function vimext#breakpoints#Clear(fname, lnum) abort
  call vimext#prompt#PromptSend("clear ".l:fname." ".a:lnum)
endfunction

function vimext#breakpoints#Delete() abort
endfunction
