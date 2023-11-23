function vimext#buffer#WinExists(winid) abort
  if a:winid == v:null
    return v:false
  endif

  let l:bnr = winbufnr(a:winid)
  return bufexists(l:bnr)
endfunction

function vimext#buffer#ClearWin(winid) abort
  let l:cwin = win_getid()

  call win_gotoid(a:winid)
  silent! %delete _

  call win_gotoid(l:cwin)
endfunction

function vimext#buffer#Wipe(buf) abort
  if !bufexists(a:buf)
    call vimext#logger#Warning("Wipe bufid not exists: ". a:buf)
    return
  endif

  execute ':bwipe! ' . a:buf
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

function vimext#buffer#NewWindowLayout(name, dr) abort
  if a:dr == 1
    execute ":vertical new ".a:name
    execute (&columns / 2 - 1) . "wincmd |"
  elseif a:dr == 2
    execute ":new ".a:name

  elseif a:dr == 3
    execute ":rightbelow new ".a:name
  endif

  return win_getid()
endfunction

function vimext#buffer#NewWindow(name, dr, basewin) abort
  let l:cwin = win_getid()

  if a:basewin != v:null
    call win_gotoid(a:basewin)
  endif

  let l:nwin = vimext#buffer#NewWindowLayout(a:name, a:dr)

  call win_gotoid(l:cwin)

  return l:nwin
endfunction
