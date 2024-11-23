let s:signs = []
let s:pc_id = 30

function s:Highlight(init, old, new) abort
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    :execute "hi " . default . "DbgPC term=reverse ctermbg=lightgrey guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    :execute "hi " . default . "DbgPC term=reverse ctermbg=darkgrey guibg=darkblue"
  endif
endfunction

function vimext#sign#Init() abort
  :call s:Highlight(1, '', &background)
  :highlight default dbgSignOn term=reverse ctermbg=red guibg=red
  :highlight default dbgSignOff term=reverse ctermbg=gray guibg=gray

  :call sign_define('DbgPC', {
        \ "linehl": 'DbgPC'
        \ })
endfunction

function vimext#sign#DeInit() abort
  :call sign_unplace('DbgDebug', {
        \ "id": s:pc_id
        \})

  :call sign_undefine('DbgPC')
endfunction

function vimext#sign#GetByBreakID(breakid) abort
  let v = []

  for sign in s:signs
    if sign.breakid == a:breakid
      :call add(v, sign)
    endif
  endfor

  return v
endfunction

function vimext#sign#Line(pc_id, fname, lnum) abort
  :execute a:lnum
  :normal! zv

  :call sign_unplace('DbgDebug', {
        \ "id": a:pc_id
        \})
  :call sign_place(a:pc_id, 'DbgDebug', 'DbgPC', a:fname, {
        \ "lnum": a:lnum,
        \ "priority": 110
        \ })
endfunction

function vimext#sign#UnPlace(self) abort
  if a:self.filename is v:null
    return
  endif

  :call sign_unplace("DbgDebug", {
        \ "buffer": a:self.filename,
        \ "id": a:self.id
        \ })
endfunction

function vimext#sign#Place(self, filename, linenum) abort
  if !bufexists(a:filename)
    return
  endif

  let a:self.linenum = a:linenum
  let a:self.filename = a:filename
  :call sign_place(a:self.id,
        \ "DbgDebug",
        \ "DbgSign" . a:self.id,
        \ a:filename,
        \ {
        \ "lnum": a:linenum,
        \ "priority": 110
        \ })
endfunction

function vimext#sign#Index(data, id) abort
  let idx = -1

  for i in range(len(a:data))
    if a:data[i].id == a:id
      return i
    endif
  endfor

  return idx
endfunction

function vimext#sign#Get(id) abort
  let idx = vimext#sign#Index(s:signs, a:id)
  if idx == -1
    return v:null
  endif

  return s:signs[idx]
endfunction

function vimext#sign#New(winid, breakid, text, enable) abort
  if strlen(a:text) > 2
    return v:null
  endif

  let hiName = "dbgSignOn"
  if a:enable == 0
    let hiName = "dbgSignOff"
  endif
  let id = a:breakid
  let osign = vimext#sign#Get(id)
  if osign isnot v:null
    :call vimext#logger#Warning("sign id repeat: " . string(osign))
    return v:null
  endif

  let nsign = {
        \ "id": id,
        \ "winid": a:winid,
        \ "breakid": a:breakid,
        \ "filename": v:null,
        \ "linenum": 0,
        \ }

  :call sign_define('DbgSign'.id, {
        \ "text": a:text,
        \ "texthl": hiName})

  :call add(s:signs, nsign)

  return nsign
endfunction

function vimext#sign#Dispose(self) abort
  let idx = vimext#sign#Index(s:signs, a:self.id)
  if idx > -1
    :call remove(s:signs, idx)
  else
    :call vimext#logger#Warning("sign id remove failed: " . string(a:self))
  endif

  :call sign_undefine('DbgSign'.a:self.id)
  :call vimext#sign#UnPlace(a:self)
endfunction
