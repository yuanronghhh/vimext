if has("unix")
  autocmd! User TermdebugStopPost :tabclose
  autocmd! User TermdebugStartPost :call vimext#debug#DebugInit()
endif

function vimext#debug#Debug(param) abort
  exec ":tabnew"
  exec ":Termdebug ".a:param
endfunction

function vimext#debug#DebugInit() abort
  let l:cwin = bufwinid(bufnr())
  let l:wins = vimext#GetWinsTab(l:cwin)
  if len(l:wins) == 0
    return
  endif

  let l:sid = l:wins[-1]
  let l:pid = l:wins[0]

  call win_execute(l:sid, "wincmd H")
  call win_execute(l:pid, "wincmd W")

  map <F10> :Over<CR>
  map <F11> :Step<CR>
  map <F8>  :Until<CR>
  map <F9>  :Break<CR>
  map <F5>  :Continue<CR>
endfunction
