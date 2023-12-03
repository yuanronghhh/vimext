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

  return vimext#breakpoint#DeleteN(a:id)
endfunction

function vimext#breakpoint#DeleteN(id)
  call remove(s:breaks, a:id)

  let l:signs = vimext#sign#GetByBreakID(a:id)
  for l:sign in l:signs
    call vimext#sign#Dispose(l:sign)
  endfor
endfunction

function vimext#breakpoint#Delete(brk)
  if a:brk is v:null
    return
  endif

  call vimext#breakpoint#DeleteID(a:brk[1])
endfunction

function vimext#breakpoint#Get(fname, lnum)
  for l:brk in values(s:breaks)
    if l:brk[7] == a:fname && l:brk[8] == a:lnum
      return l:brk
    endif
  endfor

  return v:null
endfunction

function vimext#breakpoint#Add(brk)
  let l:winid = win_getid()
  if a:brk[0] != 4
    call vimext#logger#Warning("break brk not correct")
    return
  endif

  if has_key(s:breaks, a:brk[1])
    return
  endif

  let s:breaks[a:brk[1]] = a:brk
  let l:sign = vimext#sign#New(l:winid, a:brk[1], a:brk[1], 1)
  if l:sign isnot v:null
    call vimext#sign#Place(l:sign, a:brk[7], a:brk[8])
  endif

endfunction

function s:SetBrks() abort
  let l:fname = expand('<afile>:p')
  let l:winid = win_getid()

  for l:brk in values(s:breaks)
    if l:brk[7] != l:fname
      continue
    endif

    let l:signs = vimext#sign#GetByBreakID(l:brk[1])
    for l:sign in l:signs
      call vimext#sign#Place(l:sign, l:brk[7], l:brk[8])
    endfor
  endfor
endfunction

function s:DeleteBrks() abort
  let l:fname = expand('<afile>:p')

  for l:brk in values(s:breaks)
    if l:brk[7] != l:fname
      continue
    endif

    let l:signs = vimext#sign#GetByBreakID(l:brk[1])
    for l:sign in l:signs
      call vimext#sign#UnPlace(l:sign)
    endfor
  endfor
endfunction

function vimext#breakpoint#Init()
  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray

  au BufRead * call s:SetBrks()
  au BufUnload * call s:DeleteBrks()
endfunction

function vimext#breakpoint#DeInit()
endfunction
