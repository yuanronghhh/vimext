function vimext#viewer#Create(name, dr, basewin, sign_id, mode) abort
  let self = {
        \ "name": a:name,
        \ "mode": a:mode,
        \ "dr": a:dr,
        \ "unique_id": v:null,
        \ "dirty": v:true,
        \ "basewin": a:basewin,
        \ "lines": v:null,
        \ "winid": 0,
        \ "buff": v:null,
        \ "fname": v:null,
        \ "lnum": v:null,
        \ "sign_id": a:sign_id,
        \ "sign_text": v:null,
        \ "Dispose": function("s:Dispose")
        \ }

  call vimext#viewer#NewBuffer(self)

  return self
endfunction

function vimext#viewer#NewBuffer(self) abort
  let winid = vimext#buffer#NewWindow(a:self.name, a:self.dr, a:self.basewin)

  if a:self.mode == 1
    let a:self.buff = v:null
  else
    let a:self.buff = winbufnr(winid)
  endif

  let a:self.winid = winid
  let a:self.unique_id = v:null
endfunction

function vimext#viewer#CreateFileMode(name, dr, basewin, sign_id) abort
  return vimext#viewer#Create(a:name, a:dr, a:basewin, a:sign_id, 1)
endfunction

function vimext#viewer#CreateTextMode(name, dr, basewin, sign_id) abort
  let viewer = vimext#viewer#Create(a:name, a:dr, a:basewin, a:sign_id, 2)

  let viewer.lines = []

  return viewer
endfunction

function vimext#viewer#GetWinID(self) abort
  return a:self.winid
endfunction

function vimext#viewer#GetBuff(self) abort
  return a:self.buff
endfunction

function vimext#viewer#Go(self) abort
  return win_gotoid(a:self.winid)
endfunction

function vimext#viewer#SignByNum(self, lnum) abort
  call vimext#sign#Line(a:self.sign_id, a:self.buff, a:lnum)
endfunction

function vimext#viewer#Load(self) abort
  call vimext#viewer#LoadByFile(a:self, a:self.fname, a:self.lnum)
endfunction

function vimext#viewer#Show(self) abort
  if vimext#viewer#IsShow(a:self)
    return
  endif

  call vimext#viewer#NewBuffer(a:self)
  if a:self.mode == 1
    call vimext#viewer#LoadByFile(a:self, a:self.fname, a:self.lnum)
  else
    call vimext#viewer#LoadByLines(a:self)
  endif
endfunction

function vimext#viewer#Clear(self) abort
  call vimext#buffer#ClearWin(a:self.winid)
endfunction

function vimext#viewer#LoadByFile(self, fname, lnum) abort
  if !filereadable(a:fname)
    return
  endif

  let cwin = win_getid()
  let a:self.fname = a:fname
  let a:self.lnum = a:lnum

  call win_gotoid(a:self.winid)

  if a:self.unique_id != a:fname
    execute ":e ".a:fname
    let a:self.buff = bufnr("%")
    :setlocal signcolumn=yes
    let a:self.unique_id = a:fname
    let a:self.dirty = v:true
  endif

  call vimext#viewer#SignByNum(a:self, a:lnum)

  call win_gotoid(cwin)
endfunction

" mode 2
function vimext#viewer#SignByText(self, text) abort
  let cwin = win_getid()

  call win_gotoid(a:self.winid)

  let lnum = search('^' . a:text)
  if lnum == 0
    return
  endif

  call vimext#viewer#SignByNum(a:self, lnum)

  call win_gotoid(cwin)
endfunction

function vimext#viewer#SetLines(self, lines) abort
  if !a:self.dirty
    return
  endif

  let a:self.lines = a:lines
endfunction

function vimext#viewer#IsDirty(self) abort
  if a:self is v:null
    return v:false
  endif

  return a:self.dirty
endfunction

function vimext#viewer#SetUniqueID(self, id) abort
  if a:self.unique_id != a:id
    call vimext#viewer#Clear(a:self)
    let a:self.dirty = v:true
    let a:self.lines = []
  else
    let a:self.dirty = v:false
  endif

  let a:self.unique_id = a:id
endfunction

function vimext#viewer#SetSignText(self, text) abort
  let a:self.sign_text = a:text
endfunction

function vimext#viewer#LoadByLines(self) abort
  let cwin = win_getid()
  call win_gotoid(a:self.winid)

  call insert(a:self.lines, a:self.unique_id . ":", 0)
  if a:self.dirty
    call append(line('$') - 1, a:self.lines)
  endif

  call vimext#viewer#SignByText(a:self, a:self.sign_text)

  call win_gotoid(cwin)
endfunction

function vimext#viewer#IsShow(self) abort
  if a:self is v:null
    return v:false
  endif

  return vimext#buffer#WinExists(a:self.winid)
endfunction

function s:Dispose(self) abort
  if a:self.winid isnot v:null
    call vimext#buffer#WipeWin(a:self.winid)
  endif

  if a:self.mode == 1
    unlet a:self.name
    unlet a:self.unique_id
  else
    unlet a:self.dirty
    unlet a:self.lines
    unlet a:self.sign_id
    unlet a:self.sign_text
  endif

  unlet a:self.winid
  unlet a:self.basewin
  unlet a:self.mode
endfunction
