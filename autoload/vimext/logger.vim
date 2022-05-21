let s:is_debug = 1

function vimext#logger#warning(msg) abort
  if s:is_debug != 1
    return
  endif

  echohl WarningMsg
  echomsg '[warning] '.string(a:msg)
  echohl None
endfunction

function vimext#logger#error(msg) abort
  if s:is_debug != 1
    return
  endif

  echohl ErrorMsg
  echoerr '[error] '.string(a:msg)
  echohl None
endfunction

function vimext#logger#info(msg) abort
  if s:is_debug != 1
    return
  endif

  echomsg '[debug] '.string(a:msg)
endfunction
