let s:is_debug = 0

function! vimext#debug#warningMsg(msg) abort
    echohl WarningMsg
    echomsg '[warning].'string(a:msg)
    echohl None
endfunction

function! vimext#debug#errorMsg(msg) abort
    echoerr '[error].'string(a:msg)
endfunction

function! vimext#debug#echomsg(mark, msg) abort
  if s:is_debug != 1
    return

  echo '[debug]'.string(a:mark) . string(a:msg)
endfunction
