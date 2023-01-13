let g:vimext_python = 0
let g:vimext_debug = 1
let g:is_fullscreen = 0
let g:vimext_c_api = 0
let g:autosave_session = 0


function vimext#init()
  let $VIM=substitute($VIM, "\\", "/", "g")
  let $VIMRUNTIME=substitute($VIMRUNTIME, "\\", "/", "g")

  if !exists("g:vim_home")
    if has("unix")
      let g:vim_home = expand("~/.vim")
    else
      let g:vim_home = substitute(expand("$VIM"), '\\', '/', 'g')
    endif

    let $vimext_home = g:vim_home."/plugins/vimext"
  endif

  let g:python_cmd = "python3"
  let g:vim_session = g:vim_home."/session"
  let &undodir = g:vim_home."/undodir"
  let g:vim_plugin = g:vim_home."/plugins"

  if !isdirectory(g:vim_session)
    call mkdir(g:vim_session)
  endif

  if !isdirectory(&undodir)
    call mkdir(&undodir)
  endif

  call vimext#session#Init()
  if has("python3")
    call vimext#python#Init()
    call vimext#autotags#Init()
  endif

  if has("libcall")
    let g:vimext_c_api = 1
  endif
endfunction

function vimext#FullScreen()
  if g:is_fullscreen == 0
    exec ":simalt ~x"
    let g:is_fullscreen = 1
  else
    exec ":simalt ~r"
    let g:is_fullscreen = 0
  endif
endfunction

function vimext#ClosePair(char)
  if getline('.')[col('.') - 1] == a:char
    return "\<Right>"
  else
    return a:char
  endif
endfunction

function vimext#DirName(name)
  let l:dname = fnamemodify(a:name, ':h')[1:]
  return l:dname
endfunction

function vimext#GetBinPath(cmd)
  let l:bpath = exepath(a:cmd)
  if len(l:bpath) == 0
    return ""
  endif

  let l:bpath = substitute(l:bpath, "\\", "/", 'g')
  let l:bpath = substitute(l:bpath, ".EXE", ".exe", 'g')
  return l:bpath
endfunction

function vimext#GetCWDPath()
  let l:bpath = getcwd()
  let l:bpath = substitute(l:bpath, "\\", "/", 'g')
  let l:bpath = substitute(l:bpath, ".EXE", ".exe", 'g')
  return l:bpath
endfunction

function vimext#TabMan(word)
  let l:word = a:word

  if strlen(l:word) == 0
    let l:word = expand("<cword>")
  endif

  exec ":tab Man -s2,3 ".l:word
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

function vimext#GetLinesEnds(endstr)
  let l:start = line('.')
  let l:end   = search(a:endstr, 'n')
  let l:lines = getline(l:start, l:end)

  return l:lines
endfunction

function vimext#GetWinsTab(winid)
  let l:winfo = getwininfo(a:winid)
  if len(l:winfo) == 0
    return []
  endif

  let l:tabnr = l:winfo[0]["tabnr"]
  let l:tabinfo = gettabinfo(l:tabnr)
  if len(l:tabinfo) == 0
    return []
  endif

  return l:tabinfo[0]["windows"]
endfunction
