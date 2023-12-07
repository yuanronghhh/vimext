vim9script

export def WinExists(winid: number)
  if winid == v:null
    return v:false
  endif

  var bnr = winbufnr(winid)
  return bufexists(bnr)
enddef

export def ClearWin(winid: number)
  var cwin = win_getid()

  call win_gotoid(winid)
  silent! %delete _

  call win_gotoid(cwin)
enddef

export def Wipe(buf: string)
  if buf is v:null || !bufexists(buf) || buf == 0
    call vimext#logger#Warning("Wipe bufid not exists: ". buf)
    return
  endif

  execute ':bwipe! ' . buf
enddef

export def WipeWin(win: number)
  var was_buf = winbufnr(win)
  if was_buf == -1
    call vimext#logger#Warning("Wipe winid not exists: ". win)
    return
  endif

  call Wipe(was_buf)
enddef

export def GetNameByWinID(wid: number)
  var bnr = winbufnr(wid)
  return substitute(bufname(bnr), "\\", "/", "g")
enddef

export def NewWindowLayout(name: string, dr: number)
  if dr == 1
    execute ":vertical new ".name
    execute (&columns / 2 - 1) . "wincmd |"
  elseif dr == 2
    execute ":new ".name

  elseif dr == 3
    execute ":rightbelow new ".name

  elseif dr == 4
    execute ":topleft new ".name
  endif

  return win_getid()
enddef

export def NewWindow(name: string, dr: number, basewin: number)
  var cwin = win_getid()

  if basewin isnot v:null
    call win_gotoid(basewin)
  endif

  var nwin = NewWindowLayout(name, dr)

  call win_gotoid(cwin)

  return nwin
enddef
