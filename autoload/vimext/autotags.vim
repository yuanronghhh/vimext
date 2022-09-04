if !has("python3")
  finish
endif

function vimext#autotags#GetCtagsCmd()
  let l:cmd = py3eval("g_atags.get_ctags_cmd(\"tags\", None)")

  return " ".join(l:cmd)
endfunction

function vimext#autotags#Rebuild()
  python3 g_atags.rebuild()
endfunction

function vimext#autotags#init()
  augroup autotag
    au!
    autocmd BufWritePost,FileWritePost * call vimext#autotags#Rebuild()
  augroup END

python3 << EOF
import vim
sys.path.insert(0, vim.eval("$vimext_home") + "./plugin/python")
from autotags import g_atags
EOF
endfunction
