function vimext#viewer#Create(name, dr, basewin, sign_id, mode) abort
  let l:self = {
        \ "name": a:name,
        \ "mode": a:mode,
        \ "unique_id": v:null,
        \ "dirty": v:false,
        \ "basewin": a:basewin,
        \ "lines": v:null,
        \ "winid": 0,
        \ "signline": 0,
        \ "sign_id": a:sign_id,
        \ "sign_text": v:null,
        \ "Dispose": function("s:Dispose")
        \ }
  let l:self.winid = vimext#buffer#NewWindow(a:name, a:dr, a:basewin)

  return l:self
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

function vimext#viewer#SignByNum(self, lnum) abort
  let l:buff = vimext#buffer#GetNameByWinID(a:self.winid)
  call vimext#sign#Line(a:self.sign_id, l:buff, a:lnum)
endfunction

function vimext#viewer#Show(self) abort
  return
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
    let a:self.source_buff = bufnr("%")
    setlocal signcolumn=yes
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

  let l:buff = vimext#buffer#GetNameByWinID(a:self.winid)
  call vimext#sign#Line(a:self.sign_id, l:buff, l:lnum)

  call win_gotoid(l:cwin)
endfunction

function vimext#viewer#AddLine(self, line) abort
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

function s:Dispose(self) abort
  if a:self.winid != v:null
    call vimext#buffer#WipeWin(a:self.winid)
  endif
endfunction
