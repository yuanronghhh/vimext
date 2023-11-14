const s:NullRepl = 'XXXNULLXXX'
function vimext#debug#DecodeMessage(quotedText, literal)
  if a:quotedText[0] != '"'
    call vimext#logger#Error('DecodeMessage(): missing quote in ' . a:quotedText)
    return
  endif

  let msg = a:quotedText
        \ ->substitute('^"\|[^\\]\zs".*', '', 'g')
        \ ->substitute('\\"', '"', 'g')
        "\ multi-byte characters arrive in octal form
        "\ NULL-values must be kept encoded as those break the string otherwise
        \ ->substitute('\\000', s:NullRepl, 'g')
        \ ->substitute('\\\o\o\o', {-> eval('"' .. submatch(0) .. '"')}, 'g')
        "\ Note: GDB docs also mention hex encodings - the translations below work
        "\       but we keep them out for performance-reasons until we actually see
        "\       those in mi-returns
        "\ \ ->substitute('\\0x\(\x\x\)', {-> eval('"\x' .. submatch(1) .. '"')}, 'g')
        "\ \ ->substitute('\\0x00', s:NullRepl, 'g')
        \ ->substitute('\\\\', '\', 'g')
        \ ->substitute(s:NullRepl, '\\000', 'g')
  if !a:literal
    return msg
          \ ->substitute('\\t', "\t", 'g')
          \ ->substitute('\\n', '', 'g')
  else
    return msg
  endif
endfunction

function vimext#debug#NewWindow(name) abort
  let l:cwin = win_getid()

  execute "vertical new ".a:name
  let l:nwin = win_getid()
  execute (&columns / 2 - 1) . "wincmd |"

  call win_gotoid(l:cwin)

  return l:nwin
endfunction

function s:StartPre() abort
  silent :$tabnew debugger
  call vimext#runner#Break("Main")
endfunction

function s:StartPost() abort
endfunction

function s:StopPre() abort
  unmap <F5>
  unmap <F6>
  unmap <F7>
  unmap <F8>
endfunction

function s:StopPost() abort
  call vimext#runner#Dispose()
  :tabclose
endfunction

function vimext#debug#Init() abort
  autocmd! User DbgDebugStartPre :call s:StartPre()
  autocmd! User DbgDebugStartPost :call s:StartPost()
  autocmd! User DbgDebugStopPre :call s:StopPre()
  autocmd! User DbgDebugStopPost :call s:StopPost()

  nnoremap <F5>  :call vimext#runner#Continue()<cr>
  nnoremap <F6>  :call vimext#runner#Next()<cr>
  nnoremap <F7>  :call vimext#runner#Step()<cr>
  nnoremap <F8>  :call vimext#runner#Break(line("."))<cr>

  call vimext#runner#Create("csharp")
  "call vimext#runner#Run("E:/Codes/REPOSITORY/TableDataLib/DotConsole/bin/Debug/net7.0/DotConsole.dll")
endfunction

