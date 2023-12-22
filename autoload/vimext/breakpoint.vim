let s:breaks = {}

function vimext#breakpoint#Parse(args)
  if a:args is v:null
    return v:null
  endif

  let info = [0, 0, 0]
  " type=1,fname,lnum
  " type=2,func_name

  let nameIdx = matchlist(a:args, '^\([^:]\+\):\(\d\+\)$')
  if len(nameIdx) > 0
    let info[0] = 1
    let info[1] = nameIdx[1]
    let info[2] = nameIdx[2]

    return info
  endif

  if a:args =~ '^\(\d\+\)$'
    let info[0] = 1
    let info[1] = v:null
    let info[2] = a:args
    return info
  endif

  if a:args =~ '^\(\w\+\)'
    let info[0] = 2
    let info[1] = a:args
    return info
  endif

  return v:null
endfunction

function vimext#breakpoint#DeleteID(id)
  let brk = get(s:breaks, a:id, v:null)
  if brk is v:null
    return
  endif

  return vimext#breakpoint#DeleteN(a:id)
endfunction

function vimext#breakpoint#DeleteN(id)

  let signs = vimext#sign#GetByBreakID(a:id)
  for sign in signs
    call vimext#sign#Dispose(sign)
  endfor
  call remove(s:breaks, a:id)
endfunction

function vimext#breakpoint#Delete(brk)
  if a:brk is v:null
    return
  endif

  call vimext#breakpoint#DeleteID(a:brk[1])
endfunction

function vimext#breakpoint#Get(fname, lnum)
  for brk in values(s:breaks)
    if brk[7] == a:fname && brk[8] == a:lnum
      return brk
    endif
  endfor

  return v:null
endfunction

function vimext#breakpoint#Add(brk)
  let winid = win_getid()
  if a:brk[0] != 4
    call vimext#logger#Warning("break brk not correct")
    return
  endif

  if has_key(s:breaks, a:brk[1])
    return
  endif

  let s:breaks[a:brk[1]] = a:brk
  let sign = vimext#sign#New(winid, a:brk[1], a:brk[1], 1)
  if sign isnot v:null
    call vimext#sign#Place(sign, a:brk[7], a:brk[8])
  endif

endfunction

function s:SetBrks() abort
  let fname = expand('<afile>:p')
  let winid = win_getid()

  for brk in values(s:breaks)
    if brk[7] != fname
      continue
    endif

    let signs = vimext#sign#GetByBreakID(brk[1])
    for sign in signs
      call vimext#sign#Place(sign, brk[7], brk[8])
    endfor
  endfor
endfunction

function s:DeleteBrks() abort
  let fname = expand('<afile>:p')

  for brk in values(s:breaks)
    if brk[7] != fname
      continue
    endif

    let signs = vimext#sign#GetByBreakID(brk[1])
    for sign in signs
      call vimext#sign#UnPlace(sign)
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
