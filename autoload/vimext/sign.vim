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
    if l:sign is v:null
      continue
    endif

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

function vimext#sign#Place(self, filename, linenum) abort
  if !bufexists(a:filename)
    return
  endif

  let a:self.filename = a:filename
  let a:self.linenum = a:linenum

  call sign_place(a:self.id,
        \ "DbgDebug",
        \ "DbgSign" . a:self.id,
        \ a:filename,
        \ {
        \ "lnum": a:linenum,
        \ "priority": 110
        \ })
endfunction

function vimext#sign#New(winid, breakid, text, enable) abort
  let l:hiName = "dbgSignOn"
  if a:enable == 0
    let l:hiName = "dbgSignOff"
  endif

  let l:id = len(s:signs) + 1
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
  if !bufexists(a:self.filename)
    return
  endif

  call sign_unplace("DbgDebug", {
        \ "buffer": a:self.filename,
        \ "id": a:self.id
        \ })
  call sign_undefine('DbgSign'.a:self.id)
  let s:signs[a:self.id - 1] = v:null
endfunction
