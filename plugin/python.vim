let g:vimext_python = 0

function python#Init()
python3 << EOF
import vim
import os

g_module_path = vim.eval("$vimext_home") + "/plugin/python"
sys.path.insert(0, g_module_path)

import VimPy
import Util
import CommentParser, GetterGenerator
from AutoTag import g_atag
EOF
  let g:vimext_python = 1

  nnoremap <leader>c :GetComment<cr>
  nnoremap <leader>g :GenGetter<cr>
  command! -nargs=? PythonDoc :call python#doc("<args>")
  command! -nargs=? JsonFormat :call python#JsonFormat()
  command! -nargs=? GetComment :call python#GetComment()
  command! -nargs=? GenGetter :call python#GenGetter()
  command! -nargs=? GenCtags :call python#GenCtags()
  autocmd! FileType python :nnoremap <buffer> <leader>b :call python#Operate(line('.'))<cr>

  augroup autotag
    :autocmd BufWritePost * :call python#ReGenCtags()
  augroup END

  let $C_HEADERS=python#GetSystemHeaderPath()
  set path+=$C_HEADERS
endfunction

function python#GetSystemHeaderPath()
  if g:vimext_python == 0
    return ""
  endif

  let ipath = py3eval("Util.get_system_header_str()")
  return ipath
endfunction

function python#Operate(lnum)
  if g:vimext_python == 0
    return
  endif

  let line = getline(a:lnum)
  let g:vimext_breakpoint_cmd = 'import pdb; pdb.set_trace()  # XXX BREAKPOINT'

  if strridx(line, g:vimext_breakpoint_cmd) != -1
    :normal dd
  else
    let plnum = prevnonblank(a:lnum)
    if &expandtab
      let indents = repeat(' ', indent(plnum))
    else
      let indents = repeat("\t", plnum / &shiftwidth)
    endif

    :call append(line('.')-1, indents.g:vimext_breakpoint_cmd)
    :normal k
  endif
endfunction

function python#save()
  if g:vimext_python == 0
    return
  endif

  if &modifiable && &modified
    try
      noautocmd write
    catch /E212/
      :call python#error("File modified and I can't save it. Please save it manually.")
      return 0
    endtry
  endif
  return expand('%') != ''
endfunction

function python#doc(word)
  if g:vimext_python == 0
    return
  endif

  let word = a:word

  if strlen(word) == 0
    let line = getline(".")
    let pre = line[:col(".") - 1]
    let suf = line[col("."):]
    let word = matchstr(pre, "[A-Za-z0-9_.]*$") . matchstr(suf, "^[A-Za-z0-9_]*")
  endif

  :execute "botright 8new __doc__"
  :execute ":%!".g:python_cmd." -m pydoc ".word
  pclose
  setlocal nomodified nomodifiable buftype=nofile bufhidden=delete noswapfile nowrap previewwindow filetype=rst
  redraw
endfunction

function python#JsonFormat()
  if g:vimext_python == 0
    return
  endif

  let array = py3eval("Util.json_format()")
  if len(array) == 0
    return
  endif

  silent! %delete _
  :call append(line('.')-1, array)
endfunction

function python#GetComment()
  if g:vimext_python == 0
    return 0
  endif

  let comment = py3eval("CommentParser.get_comment()")
  :call append(line('.')-1, comment)
endfunction

function python#GenGetter()
  if g:vimext_python == 0
    return 0
  endif

  let array = py3eval("GetterGenerator.gen_c_getter_setter()")

  if len(array) == 0
    return 0
  endif

  :call append(line('.')-1, array)
  :call deletebufline('%', line('.'))
endfunction

function python#ReGenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atag.regen_tags()
endfunction

function python#GenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atag.gen_tags()
endfunction

function python#DeInit()
  python3 g_atag.deinit()
endfunction

if has("python3")
  :call python#Init()
  autocmd! ExitPre * :call python#DeInit()
endif
