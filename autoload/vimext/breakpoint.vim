let s:breaks = {}

function vimext#breakpoint#Parse(args)
  if a:args is v:null
    return v:null
  endif

  let l:info = [0, 0, 0]
  " type=1,fname,lnum
  " type=2,func_name

  let l:nameIdx = matchlist(a:args, '^\([^:]\+\):\(\d\+\)$')
  if len(l:nameIdx) > 0
    let l:info[0] = 1
    let l:info[1] = vimext#debug#DecodeMessage('"' . l:nameIdx[1] . '"')
    let l:info[2] = l:nameIdx[2]

    return l:info
  endif

  if a:args =~ '^\(\d\+\)$'
    let l:info[0] = 1
    let l:info[1] = v:null
    let l:info[2] = a:args
    return l:info
  endif

  if a:args =~ '^\(\w\+\)'
    let l:info[0] = 2
    let l:info[1] = a:args
    return l:info
  endif

  return v:null
endfunction

function vimext#breakpoint#DeleteID(id)
  let l:brk = get(s:breaks, a:id, v:null)
  if l:brk is v:null
    return
  endif

  call vimext#breakpoint#Delete(l:brk)
endfunction

function vimext#breakpoint#Delete(brk)
  if a:brk is v:null
    return
  endif

  if !has_key(s:breaks, a:brk[1])
    return
  endif

  call remove(s:breaks, a:brk[1])
  let l:signs = vimext#sign#GetByBreakID(a:brk[1])

  for l:sign in l:signs
    call vimext#sign#Dispose(l:sign)
    unlet l:sign
  endfor
endfunction

function vimext#breakpoint#Get(fname, lnum)
  for l:brk in values(s:breaks)
    if l:brk[7] == a:fname && l:brk[8] == a:lnum
      return l:brk
    endif
  endfor

  return v:null
endfunction

function vimext#breakpoint#Add(info)
  if a:info[0] != 4
    call vimext#logger#Warning("break info not correct")
    return
  endif

  if !bufexists(a:info[7])
    return
  endif

  let s:breaks[a:info[1]] = a:info

  let l:winid = win_getid()
  let l:sign = vimext#sign#New(l:winid, a:info[1], a:info[1], 1)
  call vimext#sign#Place(l:sign, a:info[7], a:info[8])
endfunction

function vimext#breakpoint#Init()
  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction

function vimext#breakpoint#DeInit()
  for l:brk in values(s:breaks)
    call vimext#breakpoint#Delete(l:brk)
  endfor
endfunction
