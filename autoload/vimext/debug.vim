autocmd! User TermdebugStopPost :tabclose
autocmd! User TermdebugStartPost :call vimext#debug#DebugInit()

function vimext#debug#Debug(param) abort
  exec ":tabnew"
  exec ":Termdebug ".a:param
endfunction

function vimext#debug#DebugInit() abort
  let l:wins = gettabinfo()[-1]["windows"]

  let l:sid = l:wins[-1]
  let l:pid = l:wins[0]

  call win_execute(l:sid, "wincmd H")
  call win_execute(l:pid, "wincmd W")
endfunction
