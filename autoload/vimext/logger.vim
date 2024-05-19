function vimext#logger#Warning(msg) abort
  :echohl WarningMsg
  :echomsg '[warning] '.string(a:msg)
  :echohl None
endfunction

function vimext#logger#Error(msg) abort
  :echohl ErrorMsg
  :echoerr '[error] '.string(a:msg)
  :echohl None
endfunction

function vimext#logger#Debug(msg) abort
  if g:vimext_debug != 1
    return
  endif

  :echomsg '[info] '.string(a:msg)
endfunction

function vimext#logger#Info(msg) abort
  :echomsg '[info] '.string(a:msg)
endfunction

function vimext#logger#ProfileStart(funcname) abort
  :execute ':profile start vim-profile.log'
  :execute ':profile func '. a:funcname
endfunction

function vimext#logger#ProfileEnd() abort
  :execute ':profile pause'
endfunction
