let s:gdb_cfg = g:vim_session."/gdb.cfg"

function vimext#debug#GetSigns(fname, lnum) abort
  let l:bks = sign_getplaced(a:fname, { "group": "DbgDebug", "lnum": a:lnum })

  if len(l:bks) > 0
    let l:signs = l:bks[0]["signs"]

    if len(l:signs) > 0
      return l:signs
    endif
  endif

  return []
endfunction

function vimext#debug#SaveSession() abort
  let l:cmd = "save breakpoints ".s:gdb_cfg
  call vimext#prompt#PromptSend(l:cmd)
endfunction

function vimext#debug#OpenSession() abort
  let l:fname = expand("%:p")
  let l:lnum = line('.')

  if !filereadable(s:gdb_cfg)
    call writefile(["break main"], s:gdb_cfg, "w")
    call vimext#breakpoints#Create(l:fname, l:lnum)
  else
    call vimext#prompt#PromptSend("source ".s:gdb_cfg)
  endif

  call vimext#breakpoints#CreateFunc("main")
  call vimext#prompt#PromptSend("r")
endfunction

function vimext#debug#HasBreak(fname, lnum) abort
  let l:signs = vimext#debug#GetSigns(a:fname, a:lnum)

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

function vimext#debug#ToggleBreakpoint() abort
  let l:lnum = line(".")
  let l:fname = expand("%:p")
  let l:bks = sign_getplaced("%", { "group": "DbgDebug", "lnum": l:lnum })
  let l:has_brk = vimext#debug#HasBreak(fname, l:lnum)

  if l:has_brk
    call vimext#prompt#PromptSend("clear ")
  else
    call vimext#prompt#PromptSend("break ".fnameescape(l:fname).":".l:lnum)
  endif

  call vimext#debug#SaveSession()
endfunction

function vimext#debug#StartPre() abort
  exec ":tabnew"
  nnoremap <F5>  :call vimext#prompt#PromptSend("continue")<cr>
  nnoremap <F6>  :call vimext#prompt#PromptSend("next")<cr>
  nnoremap <F7>  :call vimext#prompt#PromptSend("step")<cr>
  nnoremap <F8>  :call vimext#debug#ToggleBreakpoint()<cr>
endfunction

function vimext#debug#StartPost() abort
  let l:cwin = bufwinid(bufnr())
  let l:wins = vimext#GetTabWins(l:cwin)

  if len(l:wins) == 0
    return
  endif

  let l:sid = l:wins[-1]
  let l:pid = l:wins[0]

  call win_execute(l:sid, "wincmd H")
  call win_execute(l:pid, "wincmd W")

  call vimext#debug#OpenSession()
endfunction

function vimext#debug#StopPre() abort
  unmap <F5>
  unmap <F6>
  unmap <F7>
  unmap <F8>
endfunction

function vimext#debug#StopPost() abort
  let s:debug_loaded = 0
  exec ":tabclose"
endfunction
