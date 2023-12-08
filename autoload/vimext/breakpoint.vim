vim9script

import "../vimext.vim" as VimExt
import "./sign.vim" as Sign
import "./logger.vim" as Logger

var breaks = {}

export def Parse(args: list<string>)
  if args is v:null
    return v:null
  endif

  var info = [0, 0, 0]
  " type=1,fname,lnum
  " type=2,func_name

  var nameIdx = matchlist(args, '^\([^:]\+\):\(\d\+\)$')
  if len(nameIdx) > 0
    var info[0] = 1
    var info[1] = VimExt.DecodeMessage('"' . nameIdx[1] . '"')
    var info[2] = nameIdx[2]

    return info
  endif

  if args =~ '^\(\d\+\)$'
    var info[0] = 1
    var info[1] = v:null
    var info[2] = args
    return info
  endif

  if args =~ '^\(\w\+\)'
    var info[0] = 2
    var info[1] = args
    return info
  endif

  return v:null
enddef

export def DeleteID(id: number)
  var brk = get(breaks, id, v:null)
  if brk is v:null
    return
  endif

  return DeleteN(id)
enddef

export def DeleteN(id: number)
  call remove(breaks, id)

  var signs = Sign.GetByBreakID(id)
  for sign in signs
    call Sign.Dispose(sign)
  endfor
enddef

export def Delete(brk: any)
  if brk is v:null
    return
  endif

  call DeleteID(brk[1])
enddef

export def Get(fname: string, lnum: number)
  for brk in values(breaks)
    if brk[7] == fname && brk[8] == lnum
      return brk
    endif
  endfor

  return v:null
enddef

export def Add(brk: any)
  var winid = win_getid()
  if brk[0] != 4
    call Logger.Warning("break brk not correct")
    return
  endif

  if has_key(breaks, brk[1])
    return
  endif

  var breaks[brk[1]] = brk
  var sign = Sign.Sign.New(winid, brk[1], brk[1], 1)
  if sign isnot v:null
    call Sign.Place(sign, brk[7], brk[8])
  endif

enddef

export def SetBrks()
  var fname = expand('<afile>:p')
  var winid = win_getid()

  for brk in values(breaks)
    if brk[7] != fname
      continue
    endif

    var signs = Sign.GetByBreakID(brk[1])
    for sign in signs
      call Sign.Place(sign, brk[7], brk[8])
    endfor
  endfor
enddef

export def DeleteBrks()
  var fname = expand('<afile>:p')

  for brk in values(breaks)
    if brk[7] != fname
      continue
    endif

    var signs = Sign.GetByBreakID(brk[1])
    for sign in signs
      call Sign.UnPlace(sign)
    endfor
  endfor
enddef

export def Init()
  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray

  au BufRead * call SetBrks()
  au BufUnload * call DeleteBrks()
enddef

export def DeInit()
enddef
