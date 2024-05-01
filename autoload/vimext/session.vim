let s:spath = "s.vim"

function vimext#session#SaveSession(sfile) abort
  let sfile = a:sfile
  let wid = win_getid()
  if strlen(a:sfile) == 0
    let sfile = "s.vim"
  endif

  if stridx(sfile, ".vim") == -1
    let sfile = a:sfile.".vim"
  endif

  if exists(":NERDTree")
    :execute ":tabdo NERDTreeClose"
    call win_gotoid(wid)
  endif

  :call vimext#logger#Info("mks! ".g:vim_session."/".sfile)
  :execute "mks! ".g:vim_session."/".sfile
endfunction

function vimext#session#SessionCompelete(A,L,P) abort
  let alist = map(globpath(g:vim_session, "*", 1, 1), "fnamemodify(v:val, ':p:t')")

  return join(alist, "\n")
endfunction

function vimext#session#OpenSession(sfile) abort
  let sfile = a:sfile
  let wid = win_getid()

  if stridx(a:sfile, ".vim") == -1
    let sfile = a:sfile.".vim"
  endif

  if strlen(a:sfile) == 0
    let sfile = "s.vim"
  endif

  let s:spath = sfile
  :execute "source ".g:vim_session."/".sfile
  :call win_gotoid(wid)

  :normal 1gt
  if exists(":NERDTree")
    :execute ":NERDTreeFind"
  endif
endfunction

function vimext#session#AutoSave() abort
  :call vimext#session#SaveSession(s:spath)
endfunction

function vimext#session#Init() abort
  if !exists("g:autosave_session") || g:autosave_session == 0
    return
  endif

  :autocmd VimLeave * :call vimext#session#AutoSave()
endfunction
