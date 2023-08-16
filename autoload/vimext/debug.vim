function vimext#debug#Debug(param) abort
  exec ":tabnew"
  exec ":Termdebug ".a:param
endfunction

function vimext#debug#GetSigns(lnum) abort
  let l:bks = sign_getplaced("%", { "group": "TermDebug", "lnum": a:lnum })

  if len(l:bks) > 0
    let l:signs = l:bks[0]["signs"]

    if len(l:signs) > 0
      return l:signs
    endif
  endif

  return []
endfunction

function vimext#debug#HasBreak(lnum) abort
  let l:signs = vimext#debug#GetSigns(a:lnum)

  if len(l:signs) == 0
    return 0
  endif

  if len(l:signs) > 0
    for l:sign in l:signs
      if stridx(l:sign["name"], "debugBreakpoint") > -1
        return 1
      endif
    endfor
  endif

  return 0
endfunction

function vimext#debug#toggleBreakpoint() abort
  let l:lnum = line(".")
  let l:bks = sign_getplaced("%", { "group": "TermDebug", "lnum": l:lnum })
  let l:has_brk = vimext#debug#HasBreak(l:lnum)

  if l:has_brk
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
