vim9script

g:vimext_python = 0

def Init()
python3 << EOF
import vim
sys.path.insert(0, vim.eval("$vimext_home") + "/plugin/python")
import utils
import CommentParser, GetterGenerator
from autotags import g_atags
EOF
  var g:vimext_python = 1

  nnoremap <leader>c :GetComment<cr>
  nnoremap <leader>g :GenGetter<cr>
  command! -nargs=? PythonDoc :call doc("<args>")
  command! -nargs=? JsonFormat :call JsonFormat()
  command! -nargs=? GetComment :call GetComment()
  command! -nargs=? GenGetter :call GenGetter()
  command! -nargs=? GenCtags :call GenCtags()
  autocmd! FileType python :nnoremap <buffer> <leader>b :call Operate(line('.'))<cr>

  augroup autotag
    autocmd BufWritePost * call ReGenCtags()
  augroup END

  var $C_HEADERS=GetSystemHeaderPath()
  set path+=$C_HEADERS
enddef

def GetSystemHeaderPath()
  if g:vimext_python == 0
    return ""
  endif

  varipath = py3eval("utils.get_system_header_str()")
  returnipath
enddef

def Operate(lnum: number)
  if g:vimext_python == 0
    return
  endif

  var line = getline(a:lnum)
  var g:vimext_breakpoint_cmd = 'import pdb; pdb.set_trace()  # XXX BREAKPOINT'

  if strridx(line, g:vimext_breakpoint_cmd) != -1
    normal dd
  else
    var plnum = prevnonblank(a:lnum)
    if &expandtab
      var indents = repeat(' ', indent(plnum))
    else
      var indents = repeat("\t", plnum / &shiftwidth)
    endif

    call append(line('.')-1, indents.g:vimext_breakpoint_cmd)
    normal k
  endif
enddef

def Save()
  if g:vimext_python == 0
    return
  endif

  if &modifiable && &modified
    try
      noautocmd write
    catch /E212/
      call error("File modified and I can't save it. Please save it manually.")
      return 0
    endtry
  endif
  return expand('%') != ''
enddef

def Doc(word: string)
  if g:vimext_python == 0
    return
  endif

  varword = a:word

  if strlen(l:word) == 0
    varline = getline(".")
    varpre =line[:col(".") - 1]
    varsuf =line[col("."):]
    varword = matchstr(pre, "[A-Za-z0-9_.]*$") . matchstr(suf, "^[A-Za-z0-9_]*")
  endif

  exe "botright 8new __doc__"
  exec ":%!" .. g:python_cmd .. " -m pydoc " .. l:word
  pclose
  setlocal nomodified nomodifiable buftype=nofile bufhidden=delete noswapfile nowrap previewwindow filetype=rst
  redraw
enddef

def JsonFormat()
  if g:vimext_python == 0
    return
  endif

  exec ":%!" .. g:python_cmd .. " -m json.tool"
enddef

def GetComment()
  if g:vimext_python == 0
    return 0
  endif

  varcomment = py3eval("CommentParser.get_comment()")
  call append(line('.')-1,comment)
enddef

def GenGetter()
  if g:vimext_python == 0
    return 0
  endif

  vararray = py3eval("GetterGenerator.gen_c_getter_setter()")

  if len(l:array) == 0
    return 0
  endif

  call append(line('.')-1,array)
  call deletebufline('%', line('.'))
enddef

def ReGenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atags.regen_tags()
enddef

def GenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atags.gen_tags()
enddef
