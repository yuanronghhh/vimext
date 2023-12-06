vim9script

var spath = "s.vim"

export def SaveSession(sfile: string)
  var sfile = sfile
  if strlen(sfile) == 0
    var sfile = "s.vim"
  endif

  if stridx(l:sfile, " .. vim") == -1
    var sfile = sfile." .. vim"
  endif

  if winnr("$") > 1
    :NERDTreeClose
  endif

  echo "mks! " .. g:vim_session."/" .. sfile
  execute "mks! " .. g:vim_session."/" .. sfile
enddef

export def SessionCompelete(A: string, L: string, P: number): string
  var alist = map(globpath(g:vim_session, "*", 1, 1), "fnamemodify(v:val, ':p:t')")

  return join(alist, "\n")
enddef

export def OpenSession(ofile: string)
  var sfile = ofile

  if stridx(sfile, ".vim") == -1
    sfile = sfile .. ".vim"
  endif

  if strlen(sfile) == 0
    sfile = "s.vim"
  endif

  spath = sfile
  echo "source " .. g:vim_session .. "/" .. sfile
  execute "source " .. g:vim_session .. "/" .. sfile
  execute ":NERDTreeFind"
enddef

export def AutoSave()
  call SaveSession(s:spath)
enddef

export def Init()
  if !exists("g:autosave_session") || g:autosave_session == 0
    return
  endif

  :autocmd VimLeave * call AutoSave()
enddef
