function vimext#buffer#WinExists(win) abort
  let l:bnr = winbufnr(a:wid)
  return bufexists(l:bnr)
endfunction

function vimext#buffer#Wipe(buf) abort
  if !bufexists(a:buf)
    call vimext#logger#Warning("Wipe bufid not exists: ". a:buf)
    return
  endif

  execute 'bwipe! ' . a:buf
endfunction

function vimext#buffer#WipeWin(win) abort
  let l:was_buf = winbufnr(a:win)
  if l:was_buf == -1
    call vimext#logger#Warning("Wipe winid not exists: ". a:win)
    return
  endif

  call vimext#buffer#Wipe(l:was_buf)
endfunction

function vimext#buffer#GetNameByWinID(wid) abort
  let l:bnr = winbufnr(a:wid)
  return bufname(l:bnr)
endfunction

function vimext#buffer#NewWindow(name) abort
  let l:cwin = win_getid()

  execute "vertical new ".a:name
  let l:nwin = win_getid()
  execute (&columns / 2 - 1) . "wincmd |"

  call win_gotoid(l:cwin)

  return l:nwin
endfunction

