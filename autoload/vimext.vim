function vimext#ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunction

function vimext#HeaderOrCode()
  let l:cext = expand("%:e")
  let l:content = expand("<cword>")

  if "cpp" == l:cext
    exec ":edit %<.hpp"
  elseif "c" == l:cext
    exec ":edit %<.h"
  else
    exec ":tag ".l:content
  endif

  call search(l:content, 'c')
endfunction

function vimext#JsonFormat()
  exec ":%!python3 -m json.tool"
endfunction

function vimext#SaveSession(sfile)
  let l:sfile = a:sfile
  if strlen(a:sfile) == 0
     let l:sfile = "s.vim"
  endif

  if stridx(l:sfile, ".vim") == -1
    let l:sfile = a:sfile.".vim"
  endif

  echo "mks! ".g:vim_session."/".l:sfile
  exec "mks! ".g:vim_session."/".l:sfile
endfunction

function vimext#SessionCompelete(A,L,P)
  let alist = map(globpath(g:vim_session, "*", 1, 1), "fnamemodify(v:val, ':p:t')")
  return join(alist, "\n")
endfunction

function vimext#OpenSession(sfile)
  let l:sfile = a:sfile

  if stridx(a:sfile, ".vim") == -1
    let l:sfile = a:sfile.".vim"
  endif

  if strlen(a:sfile) == 0
     let l:sfile = "s.vim"
  endif

  echo "source ".g:vim_session."/".l:sfile
  exec "source ".g:vim_session."/".l:sfile
endfunction

function! vimext#SetUp()
  call vimext#config#LoadConfig()
endfunction
