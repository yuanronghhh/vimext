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
  let l:extensions = ['*.c', '*.h' , '*.cpp' , '*.hpp' , '*.py' , '*.cs' , '*.js' , 'CMakeLists.txt', '*.cmake', '*.lua']
  let l:cmd = "find ./ -type f -name '".join(l:extensions, "' -or -name '")."' | xargs -d '\\n' ctags --extras=+f -a"
  let l:tfiles = tagfiles()
  let l:nname = ""

  if len(l:tfiles) == 0
    exec "silent :!".l:cmd
  endif

  if "cpp" == l:cext || "c" == l:cext
    let l:nname = expand("%<").".h"
    if filereadable(l:nname)
      exec ":edit ".l:nname
      call search(l:content, 'c')
    endif
  else
    exec ":silent! tag! ".l:content
  endif
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

  :NERDTreeClose
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
  :NERDTreeFind
endfunction

function! vimext#SetUp()
  call vimext#config#LoadConfig()
endfunction
