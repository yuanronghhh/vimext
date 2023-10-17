"
" some code from python-mode https://github.com/python-mode/python-mode.git
"
let g:vimext_python = 0

function python#Init()
python3 << EOF
import vim
sys.path.insert(0, vim.eval("$vimext_home") + "/plugin/python")
import utils
import CommentParser, GetterGenerator
EOF
  let g:vimext_python = 1
  python3 from autotags import g_atags

  nnoremap <leader>c :GetComment<cr>
  nnoremap <leader>g :GenGetter<cr>
  command! -nargs=? PythonDoc :call python#doc("<args>")
  command! -nargs=? JsonFormat :call python#JsonFormat()
  command! -nargs=? GetComment :call python#GetComment()
  command! -nargs=? GenGetter :call python#GenGetter()
  command! -nargs=? GenCtags :call python#GenCtags()
  autocmd! FileType python :nnoremap <buffer> <leader>b :call python#Operate(line('.'))<cr>

  augroup autotag
    au!
    autocmd BufWritePost * call python#ReGenCtags()
  augroup END

  let $C_HEADERS=python#GetSystemHeaderPath()
  set path+=$C_HEADERS
endfunction

function python#GetSystemHeaderPath()
  if g:vimext_python == 0
    return ""
  endif

  let l:ipath = py3eval("utils.get_system_header_str()")
  return l:ipath
endfunction

function python#Operate(lnum)
  if g:vimext_python == 0
    return
  endif

  let line = getline(a:lnum)
  let g:vimext_breakpoint_cmd = 'import pdb; pdb.set_trace()  # XXX BREAKPOINT'

  if strridx(line, g:vimext_breakpoint_cmd) != -1
    normal dd
  else
    let plnum = prevnonblank(a:lnum)
    if &expandtab
      let indents = repeat(' ', indent(plnum))
    else
      let indents = repeat("\t", plnum / &shiftwidth)
    endif

    call append(line('.')-1, indents.g:vimext_breakpoint_cmd)
    normal k
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
      call python#error("File modified and I can't save it. Please save it manually.")
      return 0
    endtry
  endif
  return expand('%') != ''
endfunction

function python#doc(word)
  if g:vimext_python == 0
    return
  endif

  let l:word = a:word

  if strlen(l:word) == 0
    let l:line = getline(".")
    let l:pre = l:line[:col(".") - 1]
    let l:suf = l:line[col("."):]
    let l:word = matchstr(pre, "[A-Za-z0-9_.]*$") . matchstr(suf, "^[A-Za-z0-9_]*")
  endif

  exe "botright 8new __doc__"
  exec ":%!".g:python_cmd." -m pydoc ".l:word
  pclose
  setlocal nomodified nomodifiable buftype=nofile bufhidden=delete noswapfile nowrap previewwindow filetype=rst
  redraw
endfunction

function python#JsonFormat()
  if g:vimext_python == 0
    return
  endif

  exec ":%!".g:python_cmd." -m json.tool"
endfunction

function python#GetComment()
  if g:vimext_python == 0
    return 0
  endif

  let l:comment = py3eval("CommentParser.get_comment()")
  call append(line('.')-1, l:comment)
endfunction

function python#GenGetter()
  if g:vimext_python == 0
    return 0
  endif

  let l:array = py3eval("GetterGenerator.gen_c_getter_setter()")

  if len(l:array) == 0
    return 0
  endif

  call append(line('.')-1, l:array)
  call deletebufline('%', line('.'))
endfunction

function python#ReGenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atags.regen_tags()
endfunction

function python#GenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atags.gen_tags()
endfunction

if has("python3")
  call python#Init()
endif
