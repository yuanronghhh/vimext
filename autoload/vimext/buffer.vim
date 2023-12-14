function vimext#buffer#WinExists(winid) abort
  if a:winid == v:null
    return v:false
  endif

  let bnr = winbufnr(a:winid)
  return bufexists(bnr)
endfunction

function vimext#buffer#ClearWin(winid) abort
  let cwin = win_getid()

  call win_gotoid(a:winid)
  silent! %delete _

  call win_gotoid(cwin)
endfunction

function vimext#buffer#Wipe(buf) abort
  if a:buf is v:null || !bufexists(a:buf) || a:buf == 0
    call vimext#logger#Warning("Wipe bufid not exists: ". a:buf)
    return
  endif

  execute ':bwipe! ' . a:buf
endfunction

function vimext#buffer#WipeWin(win) abort
  call win_execute(a:win, "close")
endfunction

function vimext#buffer#GetNameByWinID(wid) abort
  let bnr = winbufnr(a:wid)
  return substitute(bufname(bnr), "\\", "/", "g")
endfunction

function vimext#buffer#NewWindowLayout(name, dr) abort
  if a:dr == 1
    execute ":vertical new ".a:name
    execute (&columns / 2 - 1) . "wincmd |"
  elseif a:dr == 2
    execute ":new ".a:name

  elseif a:dr == 3
    execute ":rightbelow new ".a:name

  elseif a:dr == 4
    execute ":topleft new ".a:name
  endif

  return win_getid()
endfunction

function vimext#buffer#NewWindow(name, dr, basewin) abort
  let cwin = win_getid()

  if a:basewin isnot v:null
    call win_gotoid(a:basewin)
  endif

  let nwin = vimext#buffer#NewWindowLayout(a:name, a:dr)

  call win_gotoid(cwin)

  return nwin
endfunction
