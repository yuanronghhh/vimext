let s:is_debug = 0

function vimext#debug#warning(msg) abort
  echohl WarningMsg
  echomsg '[warning] '.string(a:msg)
  echohl None
endfunction

function vimext#debug#error(msg) abort
  echohl ErrorMsg
  echoerr '[error] '.string(a:msg)
  echohl None
endfunction

function vimext#debug#info(msg) abort
  if s:is_debug != 1
    return

  echo '[debug] '.string(a:mark) . string(a:msg)
endfunction
