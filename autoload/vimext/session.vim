vim9script

var spath = "s.vim"

export def SaveSession(sfile: string)
  let sfile = sfile
  if strlen(sfile) == 0
    let sfile = "s.vim"
  endif

  if stridx(l:sfile, " .. vim") == -1
    let sfile = sfile." .. vim"
  endif

  if winnr("$") > 1
    :NERDTreeClose
  endif

  echo "mks! " .. g:vim_session."/" .. sfile
  execute "mks! " .. g:vim_session."/" .. sfile
enddef

def SessionCompelete(A: number, L: number, P: number)
  let alist = map(globpath(g:vim_session, "*", 1, 1), "fnamemodify(v:val, ':p:t')")

  return join(alist, "\n")
enddef

def OpenSession(sfile: string)
  let sfile = sfile

  if stridx(sfile, ".vim") == -1
    let sfile = sfile.".vim"
  endif

  if strlen(sfile) == 0
    let sfile = "s.vim"
  endif

  var spath = sfile
  echo "source " .. g:vim_session."/" .. sfile
  execute "source " .. g:vim_session."/" .. sfile
  :NERDTreeFind
enddef

def AutoSave()
  call SaveSession(s:spath)
enddef

export def Init()
  if !exists("g:autosave_session") || g:autosave_session == 0
    return
  endif

  :autocmd VimLeave * call AutoSave()
enddef
