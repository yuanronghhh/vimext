const s:NullRepl = 'XXXNULLXXX'
function vimext#debug#DecodeFilePath(filepath)
  if a:filepath is v:null
    return v:null
  endif

  let msg = substitute(a:filepath, "\\", "/", "g")
  let msg = substitute(msg, "//", "/", "g")
  let msg = substitute(msg, "\"", "", "g")

  if msg =~ '^/\(\w\)/'
    let nameIdx = matchlist(msg, '^/\(\w\)/')
    if len(nameIdx) == 0
      return msg
    endif

    let disk = toupper(nameIdx[1])
    let msg = disk .. ":" .. msg[2:]
  endif

  return msg
endfunction

function vimext#debug#DecodeText(msgstr)
  if a:msgstr[0] != '"'
    :call vimext#logger#Error('DecodeMessage(): missing quote in ' . a:msgstr)
    return
  endif

  return a:msgstr
        \ ->substitute('^"\|[^\\]\zs".*', '', 'g')
        \ ->substitute('\\"', '"', 'g')
        \ ->substitute('\\000', s:NullRepl, 'g')
        \ ->substitute('\\\o\o\o', {-> eval('"' .. submatch(0) .. '"')}, 'g')
        \ ->substitute('\\\\', '\', 'g')
        \ ->substitute(s:NullRepl, '\\000', 'g')
        \ ->substitute('\\t', "\t", 'g')
        \ ->substitute('\\r\\n', '\n', 'g')
        \ ->substitute('\\n', '\n', 'g')
endfunction

function vimext#debug#DecodeMessage2(msgstr)
  let msg = vimext#debug#DecodeText(a:msgstr)
  return split(msg, '\n')
endfunction

function vimext#debug#DecodeMessage(quotedText, literal)
  if a:quotedText[0] != '"'
    :call vimext#logger#Error('DecodeMessage(): missing quote in ' . a:quotedText)
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
  :nnoremap <F5>  :call vimext#runner#Continue()<cr>
  :nnoremap <F6>  :call vimext#runner#Next()<cr>
  :nnoremap <S-F5>  :call vimext#runner#ReRun()<cr>
  :nnoremap <S-F6> :call vimext#runner#Finish()<cr>
  :nnoremap <F7>  :call vimext#runner#Step()<cr>
  :nnoremap <F8>  :call vimext#runner#Break(line("."))<cr>

  :execute ":silent tabnew"
endfunction

function s:StartPost() abort
endfunction

function s:StopPre() abort
endfunction

function s:StopPost() abort
  :unmap <F5>
  :unmap <F6>
  :unmap <F7>
  :unmap <F8>

  :call vimext#runner#Dispose()
  :execute ":redraw!"
endfunction

function s:StartDebug(bang, ...) abort
  if len(a:000) < 1
    return
  endif
  let lang = a:000[0]

  let pargs = []
  if len(a:000) > 1
    let pargs = a:000[1:]
  endif

  if vimext#runner#Create(lang, pargs) is v:null
    return
  endif

  :call vimext#runner#Run(pargs)
endfunction

function vimext#debug#Init() abort
  :autocmd! User DbgDebugStartPre :call s:StartPre()
  :autocmd! User DbgDebugStartPost :call s:StartPost()
  :autocmd! User DbgDebugStopPre :call s:StopPre()
  :autocmd! User DbgDebugStopPost :call s:StopPost()

  :command -nargs=* -complete=file -bang DbgDebug :call s:StartDebug(<bang>0, <f-args>)
  :command DbgAsm :call vimext#runner#Asm()
  :command DbgSource :call vimext#runner#Source()
  :command DbgSave :call vimext#runner#SaveBrks()
endfunction

function vimext#debug#DeInit() abort
  :delcommand DbgDebug
endfunction
