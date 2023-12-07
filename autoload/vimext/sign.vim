vim9script

var signs = []
var pc_id = 30

def Highlight(init: bool, old: string, new: string)
  var default = init ? 'default ' : ''
  if new ==# 'light' && old !=# 'light'
    exe "hi " . default . "DbgPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif new ==# 'dark' && old !=# 'dark'
    exe "hi " . default . "DbgPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif
enddef

export def Init()
  call Highlight(1, '', &background)
  hi default dbgSignOn term=reverse ctermbg=red guibg=red
  hi default dbgSignOff term=reverse ctermbg=gray guibg=gray

  call sign_define('DbgPC', {
        \ "linehl": 'DbgPC'
        \ })
enddef

def DeInit()
  call sign_unplace('DbgDebug', {
        \ "id": pc_id
        \})

  call sign_undefine('DbgPC')
enddef

export def GetByBreakID(breakid: number)
  var v = []

  for sign in signs
    if sign.breakid == breakid
      call add(v, sign)
    endif
  endfor

  return v
enddef

class Sign
  def new(winid: number, breakid: number, text: string, enable: bool)
    if len(text) > 2
      return v:null
    endif

    var hiName = "dbgSignOn"
    if enable == 0
      var hiName = "dbgSignOff"
    endif
    var id = breakid
    var osign = Get(id)
    if osign isnot v:null
      call Logger.Warning("sign id repeat: " . string(osign))
      return v:null
    endif

    var nsign = {
          \ "id": id,
          \ "winid": winid,
          \ "breakid": breakid,
          \ "filename": v:null,
          \ "linenum": 0,
          \ }

    call sign_define('DbgSign'.id, {
          \ "text": text,
          \ "texthl": hiName})

    call add(signs, nsign)

    return nsign
  enddef

  def Line(pcid: number, fname: string, lnum: number)
    exe lnum
    normal! zv

    call sign_unplace('DbgDebug', {
          \ "id": pcid
          \})
    call sign_place(pcid, 'DbgDebug', 'DbgPC', fname, {
          \ "lnum": lnum,
          \ "priority": 110
          \ })
  enddef

  def UnPlace()
    if this.filename is v:null
      return
    endif

    call sign_unplace("DbgDebug", {
          \ "buffer": this.filename,
          \ "id": this.id
          \ })
  enddef

  def Place(filename: string, linenum: number)
    this.filename = filename
    this.linenum = linenum

    if bufexists(filename)
      call sign_place(this.id,
            \ "DbgDebug",
            \ "DbgSign" . this.id,
            \ filename,
            \ {
            \ "lnum": linenum,
            \ "priority": 110
            \ })
    endif
  enddef

  def Get(id: number)
    var idx = indexof(signs, { v -> v:val.id is id})
    if idx == -1
      return v:null
    endif

    return signs[idx]
  enddef

  def Dispose()
    call this.UnPlace()
    call sign_undefine('DbgSign'.this.id)
    var idx = indexof(signs, { v -> v:val is this})
    call remove(signs, idx)
  enddef
endclass
