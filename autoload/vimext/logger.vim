function vimext#logger#Warning(msg) abort
  if g:vimext_debug != 1
    return
  endif

  echohl WarningMsg
  echomsg '[warning] '.string(a:msg)
  echohl None
endfunction

function vimext#logger#Error(msg) abort
  if g:vimext_debug != 1
    return
  endif

  echohl ErrorMsg
  echoerr '[error] '.string(a:msg)
  echohl None
endfunction

function vimext#logger#Info(msg) abort
  if g:vimext_debug != 1
    return
  endif

  echomsg '[info] '.string(a:msg)
endfunction
