let s:spath = "s.vim"

function vimext#session#SaveSession(sfile)
  let l:sfile = a:sfile
  if strlen(a:sfile) == 0
    let l:sfile = "s.vim"
  endif

  if stridx(l:sfile, ".vim") == -1
    let l:sfile = a:sfile.".vim"
  endif

  if winnr("$") > 1
    :NERDTreeClose
  endif

  echo "mks! ".g:vim_session."/".l:sfile
  exec "mks! ".g:vim_session."/".l:sfile
endfunction

function vimext#session#SessionCompelete(A,L,P)
  let alist = map(globpath(g:vim_session, "*", 1, 1), "fnamemodify(v:val, ':p:t')")

  return join(alist, "\n")
endfunction

function vimext#session#OpenSession(sfile)
  let l:sfile = a:sfile

  if stridx(a:sfile, ".vim") == -1
    let l:sfile = a:sfile.".vim"
  endif

  if strlen(a:sfile) == 0
    let l:sfile = "s.vim"
  endif

  let s:spath = l:sfile
  echo "source ".g:vim_session."/".l:sfile
  exec "source ".g:vim_session."/".l:sfile
  :NERDTreeFind
endfunction

function vimext#session#AutoSave()
  call vimext#session#SaveSession(s:spath)
endfunction

function vimext#session#Init()
  if !exists("g:autosave_session") || g:autosave_session == 0
    return
  endif

  :autocmd VimLeave * call vimext#session#AutoSave()
endfunction
