"
" some code from python-mode https://github.com/python-mode/python-mode.git
"
function vimext#python#Init()
python3 << EOF
import vim
sys.path.insert(0, vim.eval("$vimext_home") + "/plugin/python")
EOF
endfunction


function vimext#python#operate(lnum)
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
