"
" code from python-mode https://github.com/python-mode/python-mode.git
"
function! vimext#pypdb#operate(lnum)
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

function! vimext#pypdb#save()
    if &modifiable && &modified
        try
            noautocmd write
        catch /E212/
            call vimext#pypdb#error("File modified and I can't save it. Please save it manually.")
            return 0
        endtry
    endif
    return expand('%') != ''
endfunction

function! vimext#pypdb#doc(word)
  let l:word = a:word

  if strlen(l:word) == 0
    let l:word = expand("<cword>")
  endif

  exec ":tabnew __doc__"
  exec ":%!python -m pydoc ".l:word
  setlocal nomodifiable
  setlocal modifiable
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal syntax=man
  setlocal nolist
endfunction
