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
  let fname = g:vim_session."/".sfile

  :call vimext#logger#Info(fname)
  :execute "mks! ".fname
  :call vimext#session#SaveOption(fname)
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

function vimext#session#SaveOption(sfile) abort
  if !filewritable(a:sfile)
    return
  endif
  let afile = glob(a:sfile)
  let usercmds = []

let current_compiler = "clang"
  if exists("b:current_compiler")
    let usercmds += [":compiler " .. b:current_compiler]
  endif

  call writefile(usercmds, afile, 'a')
endfunction

function vimext#session#Init() abort
  if !exists("g:autosave_session") || g:autosave_session == 0
    return
  endif

  :autocmd VimLeave * :call vimext#session#AutoSave()
  :autocmd! SessionWritePost :call vimext#session#SaveOption()
endfunction

