vim9script

import "./vimext/session.vim" as Session
import "../plugin/python.vim" as Python

var is_fullscreen = 0
g:vimext_python = 0
g:vimext_debug = 1
g:vimext_c_api = 0

export def Init()
  $VIM = substitute($VIM, "\\", "/", "g")
  $VIMRUNTIME = substitute($VIMRUNTIME, "\\", "/", "g")

  if !exists("g:vim_home")
    if has("unix")
      g:vim_home = expand("~/.vim")
    else
      g:vim_home = substitute(expand("$VIM"), '\\', '/', 'g')
    endif

    $vimext_home = g:vim_home .. "/plugins/vimext"
  endif

  g:python_cmd = "python3"
  g:vim_session = g:vim_home .. "/session"
  g:vim_plugin = g:vim_home .. "/plugins"
  &undodir = g:vim_home .. "/undodir"

  if !isdirectory(g:vim_session)
    call mkdir(g:vim_session)
  endif

  if !isdirectory(&undodir)
    call mkdir(&undodir)
  endif

  call Session.Init()

  if has("libcall")
    g:vimext_c_api = 1
  endif

  if has("python3")
    autocmd! BufRead * ++once call Python.Init()
  endif
enddef

def FullScreen()
  if is_fullscreen == 0
    execute ":simalt ~x"
    is_fullscreen = 1
  else
    execute ":simalt ~r"
    is_fullscreen = 0
  endif
enddef

def ClosePair(chr: string)
  if getline('.')[col('.') - 1] == chr
    return "\<Right>"
  else
    return chr
  endif
enddef

def DirName(name: string)
  var dname = fnamemodify(name, ':h')[1:]
  return dname
enddef

export def GetBinPath(cmd: string): string
  var bpath = exepath(cmd)
  if len(bpath) == 0
    return ""
  endif

  bpath = substitute(bpath, "\\", "/", 'g')
  bpath = substitute(bpath, ".EXE", ".exe", 'g')

  return bpath
enddef

def GetCWDPath()
  var bpath = getcwd()
  var bpath = substitute(bpath, "\\", "/", 'g')
  var bpath = substitute(bpath, ".EXE", ".exe", 'g')
  return bpath
enddef

def TabMan(word: string)
  if strlen(word) == 0
    var word = expand("<cword>")
  endif

  exec ":tab Man -s2,3 " . word
enddef

def HeaderOrCode()
  var cext = expand("%:e")
  var emap = [
        \ ["c", 1, ["h", "hpp"]],
        \ ["cpp", 1, ["h", "hpp"]],
        \ ["h", 0, ["cpp", "c"]],
        \ ["hpp", 0, ["cpp", "c"]]
        \ ]
  var content = expand("<cword>")
  var nname = ""
  var ftags = taglist(content)

  for item in emap
    if item[0] != cext
      continue
    endif

    for j in item[2]
      var tname = expand("%<")."." .. j

      if !filereadable(tname)
        continue
      endif

      var nname = tname
      exec ":edit " .. nname

      break
    endfor

    if !l:item[1] && len(ftags) > 0
      exec ":silent! tag! " .. content
    endif

    break
  endfor

  if nname == "" && len(ftags) > 0
    exec ":silent! tag! " .. content
  endif

  call search(content, 'c')
enddef

def GetLinesEnds(endstr: string)
  var start = line('.')
  var end   = search(endstr, 'n')
  var lines = getline(start, end)

  return lines
enddef

def GetTabWins(winid: number)
  var winfo = getwininfo(winid)
  if len(winfo) == 0
    return []
  endif

  var tabnr = winfo[0]["tabnr"]
  var tabinfo = gettabinfo(tabnr)
  if len(tabinfo) == 0
    return []
  endif

  return tabinfo[0]["windows"]
enddef

def GetTabInfo(winid: number)
  var winfo = getwininfo(winid)
  if len(winfo) == 0
    return []
  endif

  var tabnr = winfo[0]["tabnr"]
  return gettabinfo(tabnr)
enddef
