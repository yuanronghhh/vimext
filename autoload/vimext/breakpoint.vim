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
    let filepath = substitute(expand("%:p"), "\\", "/", "g")

    let info[0] = 1
    let info[1] = filepath
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
    :call vimext#sign#Dispose(sign)
  endfor
  :call remove(s:breaks, a:id)
endfunction

function vimext#breakpoint#Delete(brk)
  if a:brk is v:null
    return
  endif

  :call vimext#breakpoint#DeleteID(a:brk[1])
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
    :call vimext#logger#Warning("break brk not correct")
    return
  endif

  if has_key(s:breaks, a:brk[1])
    return
  endif

  let s:breaks[a:brk[1]] = a:brk
  let sign = vimext#sign#New(winid, a:brk[1], a:brk[1], 1)
  if sign isnot v:null
    :call vimext#sign#Place(sign, a:brk[7], a:brk[8])
  endif
endfunction

function s:SetBrks() abort
  let fname = vimext#debug#DecodeFilePath(expand('%:p'))
  let winid = win_getid()

  for brk in values(s:breaks)
    if brk[7] != fname
      continue
    endif

    let signs = vimext#sign#GetByBreakID(brk[1])
    for sign in signs
      :call vimext#sign#Place(sign, brk[7], brk[8])
    endfor
  endfor
endfunction

function s:DeleteBrks(isDestroy) abort
  let fname = vimext#debug#DecodeFilePath(expand('%:p'))
  for brk in values(s:breaks)
    if brk[7] != fname
      continue
    endif

    let signs = vimext#sign#GetByBreakID(brk[1])
    for sign in signs
      if a:isDestroy
        :call vimext#sign#Dispose(sign)
      else
        :call vimext#sign#UnPlace(sign)
      endif
    endfor
  endfor

  if a:isDestroy
    for brk in values(s:breaks)
      :call vimext#breakpoint#Delete(brk)
    endfor
  endif
endfunction

function vimext#breakpoint#Init()
  :highlight default dbgBreakpoint term=reverse ctermbg=red guibg=red
  :highlight default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray

  au BufRead * :call s:SetBrks()
  au BufUnload * :call s:DeleteBrks(v:false)
endfunction

function vimext#breakpoint#DeInit()
  :call s:DeleteBrks(v:true)
endfunction

function vimext#breakpoint#Print()
  :call vimext#logger#Debug(s:breaks)
endfunction
