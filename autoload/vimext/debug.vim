if has("unix")
  autocmd! User TermdebugStopPost :tabclose
  autocmd! User TermdebugStartPost :call vimext#debug#DebugInit()
endif

function vimext#debug#Debug(param) abort
  exec ":tabnew"
  exec ":Termdebug ".a:param
endfunction

function vimext#debug#toggleBreakpoint() abort
  let l:lnum = line(".")
  let l:bks = sign_getplaced("%", { "group": "TermDebug", "lnum": l:lnum })

  if len(l:bks) > 0 &&len(l:bks[0]["signs"]) > 0
    exec ":Clear"
  else
    exec ":Break ".l:lnum
  endif
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

  nnoremap <F5>  :Continue<cr>
  nnoremap <F6>  :Over<cr>
  nnoremap <F7>  :Step<cr>
  nnoremap <F8>  :call vimext#debug#toggleBreakpoint()<cr>

  exec ":Break main"
  exec ":Run"
endfunction
