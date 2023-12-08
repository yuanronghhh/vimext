vim9script

export def Warning(msg: any)
  if !g:vimext_debug
    return
  endif

  echohl WarningMsg
  echomsg '[warning] ' .. string(msg)
  echohl None
enddef

export def Error(msg: any)
  if !g:vimext_debug
    return
  endif

  throw '[error] ' .. string(msg)
enddef

export def Info(msg: any)
  if !g:vimext_debug
    return
  endif

  echomsg '[info] ' .. string(msg)
enddef

export def ProfileStart(funcname: any)
  execute ':profile start vim-profile.log'
  execute ':profile func ' .. funcname
enddef

export def ProfileEnd()
  execute ':profile pause'
enddef
