let s:gdb_cfg = g:vim_session."/gdb.cfg"
let s:pc_id = 30
let s:signs = []

function vimext#sign#Init()
  hi default dbgSignOn term=reverse ctermbg=red guibg=red
  hi default dbgSignOff term=reverse ctermbg=gray guibg=gray
  call sign_define('DbgPC', #{linehl: 'DbgPC'})
endfunction

function vimext#sign#DeInit()
endfunction

function vimext#sign#Remove(self, buff, id) abort
  if !bufexists(a:buff)
    return
  endif

  call sign_undefine('DbgSign'.a:id)
  call sign_unplace("DbgDebug", {
        \ "buffer": a:buff,
        \ "id": a:id})
endfunction

function vimext#sign#NewLine(fname, lnum, brkid)
endfunction

function vimext#sign#New(buffname, breakid, filename, linenum, text)
  let l:hiName = "dbgSignOn"
  if a:flag == 0
    let l:hiName = "dbgSignOff"
  endif

  if !bufexists(a:filename)
    return
  endif

  let l:nsign = [len(s:signs), a:breakid, a:filename, a:linenum, a:text]
  return l:nsign
endfunction

function vimext#sign#PlaceSign(self, filename, linenum, id, text, flag)
  let l:hiName = "dbgSignOn"
  if a:flag == 0
    let l:hiName = "dbgSignOff"
  endif

  if !bufexists(a:filename)
    return
  endif

  call sign_define('DbgSign'.a:id, {
        \ "text": a:text,
        \ "texthl": l:hiName})

  call sign_place(a:id,
        \ "DbgDebug",
        \ "DbgSign" . a:id,
        \ a:filename,
        \ #{lnum: a:linenum, priority: 110})
endfunction

function vimext#sign#SignLine(sign) abort
  exe a:lnum
  normal! zv

  if a:clean == 1
    call sign_unplace('DbgDebug', #{id: s:pc_id})
  endif

  setlocal signcolumn=yes
  call sign_place(s:pc_id, 'DbgDebug', 'DbgPC', a:fname, #{lnum: a:lnum, priority: 110})
endfunction
