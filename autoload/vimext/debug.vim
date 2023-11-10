function vimext#debug#Init() abort
  let l:gdb_cmd = exepath("gdb")

  if len(l:gdb_cmd) != 0
    autocmd! User DbgDebugStartPre :call vimext#debug#StartPre()
    autocmd! User DbgDebugStartPost :call vimext#debug#StartPost()
    autocmd! User DbgDebugStopPre :call vimext#debug#StopPre()
    autocmd! User DbgDebugStopPost :call vimext#debug#StopPost()
  endif
endfunction

function vimext#debug#StartPre() abort
  exec ":tabnew"
  nnoremap <F5>  :Continue<cr>
  nnoremap <F6>  :Over<cr>
  nnoremap <F7>  :Step<cr>
  nnoremap <F8>  :ToggleBreakpoint<cr>
endfunction

function vimext#debug#StartPost() abort
  call vimext#prompt#SendCmd("run")
endfunction

function vimext#debug#StopPre() abort
  unmap <F5>
  unmap <F6>
  unmap <F7>
  unmap <F8>
endfunction

function vimext#debug#StopPost() abort
  exec ":tabclose"
endfunction
