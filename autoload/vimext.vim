function vimext#ClosePair(char)
  if getline('.')[col('.') - 1] == a:char
    return "\<Right>"
  else
    return a:char
  endif
endfunction

function vimext#DirName(name)
  return fnamemodify(a:name, ':h')."\""
endfunction

function vimext#GetBinPath(cmd)
  let l:bpath = exepath(a:cmd)
  let l:bpath = substitute(l:bpath, "\\", "/", 'g')
  let l:bpath = substitute(l:bpath, ".EXE", ".exe", 'g')
  return l:bpath
endfunction

function vimext#GenCtags()
  let l:extensions = ['*.c', '*.h' , '*.cpp' , '*.hpp' , '*.py' , '*.cs' , '*.js' , 'CMakeLists.txt', '*.cmake', '*.lua']
  let l:cmd = "find ./ -type f -name '".join(l:extensions, "' -or -name '")."' | xargs -d '\\n' ctags -a"

  exec ":!".l:cmd
endfunction

function vimext#HeaderOrCode()
  let l:cext = expand("%:e")
  let l:emap = [
        \ ["c", 1, ["h", "hpp"]],
        \ ["cpp", 1, ["h", "hpp"]],
        \ ["h", 0, ["cpp", "c"]],
        \ ["hpp", 0, ["cpp", "c"]]
        \ ]
  let l:content = expand("<cword>")
  let l:nname = ""
  let l:ftags = taglist(l:content)

  for l:item in l:emap
    if l:item[0] != l:cext
      continue
    endif

    for j in l:item[2]
      let l:tname = expand("%<").".".l:j

      if !filereadable(l:tname)
        continue
      endif

      let l:nname = l:tname
      exec ":edit ".l:nname

      break
    endfor

    if !l:item[1] && len(l:ftags) > 0
      exec ":silent! tag! ".l:content
    endif

    break
  endfor

  if l:nname == "" && len(l:ftags) > 0
    exec ":silent! tag! ".l:content
  endif

  call search(l:content, 'c')
endfunction

function vimext#JsonFormat()
  exec ":%!".g:python_cmd." -m json.tool"
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

function vimext#SetUp()
  call vimext#config#LoadConfig()
endfunction
