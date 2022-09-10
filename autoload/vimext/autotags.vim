function vimext#autotags#GetCtagsCmd()
  let l:cmd = py3eval("g_atags.get_ctags_cmd(\"tags\", None)")

  return " ".join(l:cmd)
endfunction

function vimext#autotags#Rebuild()
  python3 g_atags.rebuild()
endfunction

function vimext#autotags#Init()
  augroup autotag
    au!
    autocmd BufWritePost,FileWritePost * call vimext#autotags#Rebuild()
  augroup END

  python3 from autotags import g_atags
endfunction
