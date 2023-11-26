function vimext#viewer#Create(name, dr, basewin, sign_id, mode) abort
  let l:self = {
        \ "name": a:name,
        \ "mode": a:mode,
        \ "dr": a:dr,
        \ "unique_id": v:null,
        \ "dirty": v:false,
        \ "basewin": a:basewin,
        \ "lines": v:null,
        \ "winid": 0,
        \ "buff": v:null,
        \ "sign_id": a:sign_id,
        \ "sign_text": v:null,
        \ "Dispose": function("s:Dispose")
        \ }

  call vimext#viewer#NewBuffer(l:self)

  return l:self
endfunction

function vimext#viewer#NewBuffer(self) abort
  let l:winid = vimext#buffer#NewWindow(a:self.name, a:self.dr, a:self.basewin)

  if a:self.mode == 1
    let a:self.buff = v:null
  else
    let a:self.buff = winbufnr(l:winid)
  endif

  let a:self.winid = l:winid
  let a:self.unique_id = v:null
endfunction

function vimext#viewer#CreateFileMode(name, dr, basewin, sign_id) abort
  return vimext#viewer#Create(a:name, a:dr, a:basewin, a:sign_id, 1)
endfunction

function vimext#viewer#CreateTextMode(name, dr, basewin, sign_id) abort
  let l:viewer = vimext#viewer#Create(a:name, a:dr, a:basewin, a:sign_id, 2)

  let l:viewer.lines = []

  return l:viewer
endfunction

function vimext#viewer#GetWinID(self) abort
  return a:self.winid
endfunction

function vimext#viewer#Go(self) abort
  return win_gotoid(a:self.winid)
endfunction

function vimext#viewer#SignByNum(self, lnum) abort
  call vimext#sign#Line(a:self.sign_id, a:self.buff, a:lnum)
endfunction

function vimext#viewer#Show(self) abort
  call vimext#viewer#NewBuffer(a:self)
endfunction

function vimext#viewer#Clear(self) abort
  call vimext#buffer#ClearWin(a:self.winid)
endfunction

function vimext#viewer#LoadByFile(self, fname, lnum) abort
  let l:cwin = win_getid()

  if !filereadable(a:fname)
    return
  endif
  call win_gotoid(a:self.winid)

  if a:self.unique_id != a:fname
    execute ":e ".a:fname
    let a:self.buff = bufnr("%")
    :setlocal signcolumn=yes
    let a:self.unique_id = a:fname
  endif
  call vimext#viewer#SignByNum(a:self, a:lnum)

  call win_gotoid(l:cwin)
endfunction

" mode 2
function vimext#viewer#SignByText(self, text) abort
  let l:cwin = win_getid()

  call win_gotoid(a:self.winid)

  let l:lnum = search('^' . a:text)
  if l:lnum == 0
    return
  endif

  call vimext#viewer#SignByNum(a:self, l:lnum)

  call win_gotoid(l:cwin)
endfunction

function vimext#viewer#AddLine(self, line) abort
  if !a:self.dirty
    return
  endif

  call add(a:self.lines, a:line)
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
  let l:cwin = win_getid()
  call win_gotoid(a:self.winid)

  if a:self.dirty
    call append(line('$') - 1, a:self.lines)
  endif

  call vimext#viewer#SignByText(a:self, a:self.sign_text)

  call win_gotoid(l:cwin)
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
