const s:NullRepl = 'XXXNULLXXX'
function vimext#debug#DecodeFilePath(quotedText)
  let l:msg = substitute(a:quotedText, "\\", "/", "g")

  return vimext#debug#DecodeMessage(l:msg, v:false)
endfunction

function vimext#debug#Highlight(init, old, new) abort
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    exe "hi " . default . "DbgPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    exe "hi " . default . "DbgPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif
endfunction

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

function s:StartPre() abort
  nnoremap <F5>  :call vimext#runner#Continue()<cr>
  nnoremap <F6>  :call vimext#runner#Next()<cr>
  nnoremap <F7>  :call vimext#runner#Step()<cr>
  nnoremap <F8>  :call vimext#runner#Break(line("."))<cr>

  execute ":silent tabnew debugger"
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
  execute ":redraw!"
endfunction

function s:StartDebug(bang, ...) abort
  if len(a:000) < 1
    return
  endif
  let l:lang = a:000[0]

  let l:pargs = ""
  if len(a:000) > 1
    let l:pargs = a:000[1]
  endif

  if vimext#runner#Create(l:lang) is v:null
    return
  endif

  call vimext#runner#Run(l:pargs)
endfunction

function vimext#debug#Init() abort
  autocmd! User DbgDebugStartPre :call s:StartPre()
  autocmd! User DbgDebugStartPost :call s:StartPost()
  autocmd! User DbgDebugStopPre :call s:StopPre()
  autocmd! User DbgDebugStopPost :call s:StopPost()

  command -nargs=* -complete=file -bang DbgDebug call s:StartDebug(<bang>0, <f-args>)
  command DbgAsm call vimext#runner#Asm()
endfunction

function vimext#debug#DeInit() abort
  delcommand DbgDebug
endfunction
