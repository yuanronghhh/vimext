"
" some code from python-mode https://github.com/python-mode/python-mode.git
"
let g:vimext_python = 0

function vimext#python#Init()
python3 << EOF
import vim
sys.path.insert(0, vim.eval("$vimext_home") + "/plugin/python")
import utils
EOF
let g:vimext_python = 1
endfunction

function vimext#python#Operate(lnum)
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

function vimext#python#save()
  if g:vimext_python == 0
    return
  endif

  if &modifiable && &modified
    try
      noautocmd write
    catch /E212/
      call vimext#python#error("File modified and I can't save it. Please save it manually.")
      return 0
    endtry
  endif
  return expand('%') != ''
endfunction

function vimext#python#doc(word)
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

function vimext#python#JsonFormat()
  if g:vimext_python == 0
    return
  endif

  exec ":%!".g:python_cmd." -m json.tool"
endfunction

function vimext#python#GetSystemHeaderPath()
  if g:vimext_python == 0
    return ""
  endif

  let l:ipath = py3eval("utils.get_system_header_str()")
  return l:ipath
endfunction

function vimext#python#GetComment()
  if g:vimext_python == 0
    return 0
  endif

  let l:comment = py3eval("utils.get_comment()")
  call append(line('.')-1, l:comment)
  call search("Variable:", "b")
endfunction
