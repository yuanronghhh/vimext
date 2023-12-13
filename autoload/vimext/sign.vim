let s:signs = []
let s:pc_id = 30

function s:Highlight(init, old, new) abort
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    exe "hi " . default . "DbgPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    exe "hi " . default . "DbgPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif
endfunction

function vimext#sign#Init() abort
  call s:Highlight(1, '', &background)
  hi default dbgSignOn term=reverse ctermbg=red guibg=red
  hi default dbgSignOff term=reverse ctermbg=gray guibg=gray

  call sign_define('DbgPC', {
        \ "linehl": 'DbgPC'
        \ })
endfunction

function vimext#sign#DeInit() abort
  call sign_unplace('DbgDebug', {
        \ "id": s:pc_id
        \})

  call sign_undefine('DbgPC')
endfunction

function vimext#sign#GetByBreakID(breakid) abort
  let l:v = []

  for l:sign in s:signs
    if l:sign.breakid == a:breakid
      call add(l:v, l:sign)
    endif
  endfor

  return l:v
endfunction

function vimext#sign#Line(pc_id, fname, lnum) abort
  exe a:lnum
  normal! zv

  call sign_unplace('DbgDebug', {
        \ "id": a:pc_id
        \})
  call sign_place(a:pc_id, 'DbgDebug', 'DbgPC', a:fname, {
        \ "lnum": a:lnum,
        \ "priority": 110
        \ })
endfunction

function vimext#sign#UnPlace(self) abort
  if a:self.filename is v:null
    return
  endif

  call sign_unplace("DbgDebug", {
        \ "buffer": a:self.filename,
        \ "id": a:self.id
        \ })
endfunction

function vimext#sign#Place(self, filename, linenum) abort
  let a:self.filename = a:filename
  let a:self.linenum = a:linenum

  if bufexists(a:filename)
    call sign_place(a:self.id,
          \ "DbgDebug",
          \ "DbgSign" . a:self.id,
          \ a:filename,
          \ {
          \ "lnum": a:linenum,
          \ "priority": 110
          \ })
  endif

endfunction

function vimext#sign#Index(data, id) abort
  let l:idx = -1

  for l:i in range(len(a:data))
    if a:data[l:i].id == a:id
      return l:i
    endif
  endfor

  return l:idx
endfunction

function vimext#sign#Get(id) abort
  let l:idx = vimext#sign#Index(s:signs, a:id)
  if l:idx == -1
    return v:null
  endif

  return s:signs[l:idx]
endfunction

function vimext#sign#New(winid, breakid, text, enable) abort
  if len(a:text) > 2
    return v:null
  endif

  let l:hiName = "dbgSignOn"
  if a:enable == 0
    let l:hiName = "dbgSignOff"
  endif
  let l:id = a:breakid
  let l:osign = vimext#sign#Get(l:id)
  if l:osign isnot v:null
    call vimext#logger#Warning("sign id repeat: " . string(l:osign))
    return v:null
  endif

  let l:nsign = {
        \ "id": l:id,
        \ "winid": a:winid,
        \ "breakid": a:breakid,
        \ "filename": v:null,
        \ "linenum": 0,
        \ }

  call sign_define('DbgSign'.l:id, {
        \ "text": a:text,
        \ "texthl": l:hiName})

  call add(s:signs, l:nsign)

  return l:nsign
endfunction

function vimext#sign#Dispose(self) abort
  let l:idx = vimext#sign#Index(s:signs, a:self.id)
  if l:idx > -1
    call remove(s:signs, l:idx)
  else
    call vimext#logger#Warning("sign id remove failed: " . string(a:self))
  endif

  call sign_undefine('DbgSign'.a:self.id)
  call vimext#sign#UnPlace(a:self)
endfunction
