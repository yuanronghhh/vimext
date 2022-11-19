function vimext#autotags#ReGenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atags.regen_tags()
endfunction

function vimext#autotags#GenCtags()
  if g:vimext_python == 0
    return
  endif

  python3 g_atags.gen_tags()
endfunction

function vimext#autotags#Init()
  if g:vimext_python == 0
    return
  endif

  augroup autotag
    au!
    autocmd BufWritePost * call vimext#autotags#ReGenCtags()
  augroup END

  python3 from autotags import g_atags
endfunction
