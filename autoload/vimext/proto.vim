function vimext#proto#Create(name) abort
  let s:mi_cmd = {
        \ "name": "mi",
        \ "Arguments": "-exec-arguments",
        \ "Break": "-break-insert",
        \ "Clear": "-break-delete",
        \ "Run": "-exec-run",
        \ "Step": "-exec-step",
        \ "Next": "-exec-next",
        \ "Finish": "-exec-finish",
        \ "Interrupt": "-exec-interrupt",
        \ "Continue": "-exec-continue",
        \ "Until": "-exec-until",
        \ "Frame": "-interpreter-exec mi frame",
        \ "Console": "-interpreter-exec console",
        \ "Source": "source",
        \ "Set": "-gdb-set",
        \ "SaveBreakoints": "save breakpoints",
        \ "DecodeLine": function("s:MIDecodeLine")
        \ }

  if a:name == "mi"
    return s:mi_cmd
  endif

  return v:null
endfunction

function s:MIDecodeLine(msg) abort
  let l:info = [0, 0, 0, 0]

  if a:msg =~ '^*stopped,reason="entry-point-hit"'
    let l:info[0] = 1

    let l:nameIdx = matchlist(a:msg, '^\*stopped,reason="entry-point-hit",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)  " filenane
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    return l:info
  endif

  if a:msg =~ '^*stopped,reason="end-stepping-range"'

    let l:nameIdx = matchlist(a:msg, '^\*stopped,reason="end-stepping-range",\S*,fullname=\([^,]*\),line="\(\d\+\)",col="\(\d\+\)"')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 5
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)  " filenane
    let l:info[2] = l:nameIdx[2]  " lineno
    let l:info[3] = l:nameIdx[3]  " col
    return l:info
  endif

  if a:msg =~ '^\^running'
    let l:info[0] = 3
    return l:info
  endif

  if a:msg =~ '^=library-loaded,'
        \ || a:msg =~ '^=symbols-loaded,'
        \ || a:msg =~ '^=no-symbols-loaded,'
        \ || a:msg =~ '^=breakpoint-modified,'
        \ || a:msg =~ '^=thread'
    let l:info[0] = 7
    return l:info
  endif

  "=message,text="ok1\n\r\n",send-to="output-window"
  if a:msg =~ '^=message,'

    let l:nameIdx = matchlist(a:msg, '^=message,text=\([^,]*\),send-to=\([^,]*\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[0] = 8
    let l:info[1] = vimext#debug#DecodeMessage(l:nameIdx[1], v:true)
    let l:info[2] = l:nameIdx[2]

    return l:info
  endif

  return l:info
endfunction

function s:CLIDecodeLine(msg) abort
  let l:info = [0, 0, 0, 0]

  if a:msg =~ '^stopped, reason: breakpoint'
    let l:info[0] = 1

    let l:nameIdx = matchlist(a:msg, 'stopped, reason: breakpoint \(\d\+\) hit, .* frame={\S* at \([^}]*\):\(\d\+\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[1] = l:nameIdx[1]  " breakpoint
    let l:info[2] = l:nameIdx[2]  " filenane
    let l:info[3] = l:nameIdx[3]  " lineno
    return l:info
  endif

  if a:msg =~ '^\^stopped, reason: exited, exit-code: 0'
    let l:info[0] = 2
    return l:info
  endif

  if a:msg =~ '^\^running'
    let l:info[0] = 3
    return l:info
  endif

  if a:msg =~ '^ Breakpoint '
    let l:info[0] = 4
    let l:nameIdx = matchlist(a:msg, ' Breakpoint \(\d\+\)')

    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[1] = l:nameIdx[1]  " breakpoint number
    return l:info
  endif

  if a:msg =~ 'stopped, reason: end stepping range,'
    let l:info[0] = 5

    let l:nameIdx = matchlist(a:msg, 'stopped, reason: end stepping range, .* frame={\S* at \([^}]*\):\(\d\+\)')
    if len(l:nameIdx) == 0
      return l:info
    endif

    let l:info[1] = l:nameIdx[1]  " filenane
    let l:info[2] = l:nameIdx[2]  " lineno
    return l:info
  endif

  if a:msg =~ '^\^exit'
    let l:info[0] = 6
    return l:info
  endif

  if a:msg =~ '^library loaded:'
              \ || a:msg =~ '^symbols loaded,'
              \ || a:msg =~ '^no symbols loaded,'
              \ || a:msg =~ '^breakpoint modified,'
              \ || a:msg =~ '^thread created,'
    let l:info[0] = 7
    return l:info
  endif

  return l:info
endfunction

function vimext#proto#Dispose(self) abort
  unlet s:mi_cmd
endfunction
