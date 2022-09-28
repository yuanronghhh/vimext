function vimext#autotags#GetCtagsCmd()
  let l:cmd = py3eval("g_atags.get_ctags_cmd(\"tags\", None)")

  return " ".join(l:cmd)
endfunction

function vimext#autotags#ReGenCtags()
  python3 g_atags.regen_tags()
endfunction

function vimext#autotags#GenCtags()
  python3 g_atags.gen_tags()
endfunction

function vimext#autotags#Init()
  augroup autotag
    au!
    autocmd BufWritePost,FileWritePost * call vimext#autotags#ReGenCtags()
  augroup END

  python3 from autotags import g_atags
endfunction
