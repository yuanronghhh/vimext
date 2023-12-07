vim9script

import "./logger.vim" as Logger
import "./runner.vim" as Runner

const NullRepl = 'XXXNULLXXX'
export def DecodeFilePath(quotedText: string)
  var msg = substitute(quotedText, "\\", "/", "g")
  var msg = substitute(msg, "//", "/", "g")
  var msg = substitute(msg, "\"", "", "g")

  return msg
enddef

def DecodeMessage(quotedText: string, literal: bool)
  if quotedText[0] != '"'
    call vimext#logger#Error('DecodeMessage(): missing quote in ' . quotedText)
    return
  endif

  var msg = quotedText
        \ ->substitute('^"\|[^\\]\zs".*', '', 'g')
        \ ->substitute('\\"', '"', 'g')
        "\ multi-byte characters arrive in octal form
        "\ NULL-values must be kept encoded as those break the string otherwise
        \ ->substitute('\\000', NullRepl, 'g')
        \ ->substitute('\\\o\o\o', {-> eval('"' .. submatch(0) .. '"')}, 'g')
        "\ Note: GDB docs also mention hex encodings - the translations below work
        "\       but we keep them out for performance-reasons until we actually see
        "\       those in mi-returns
        "\ \ ->substitute('\\0x\(\x\x\)', {-> eval('"\x' .. submatch(1) .. '"')}, 'g')
        "\ \ ->substitute('\\0x00', NullRepl, 'g')
        \ ->substitute('\\\\', '\', 'g')
        \ ->substitute(NullRepl, '\\000', 'g')
  if !literal
    return msg
          \ ->substitute('\\t', "\t", 'g')
          \ ->substitute('\\n', '', 'g')
  else
    return msg
  endif
enddef

def StartPre()
  nnoremap <F5>  :call Runner.Continue()<cr>
  nnoremap <F6>  :call Runner.Next()<cr>
  nnoremap <F7>  :call Runner.Step()<cr>
  nnoremap <F8>  :call Runner.Break(line("."))<cr>

  execute ":silent tabnew"
enddef

def StartPost()
enddef

def StopPre()
  unmap <F5>
  unmap <F6>
  unmap <F7>
  unmap <F8>
enddef

def StopPost()
  call Runner.Dispose()
  execute ":redraw!"
enddef

def StartDebug(bang: number, ...args: list<string>)
  if len(args) < 1
    return
  endif
  var lang = args[0]

  var pargs: list<string> = []
  if len(args) > 1
    pargs = args[1 : ]
  endif

  if Runner.Create(lang, pargs) is v:null
    return
  endif

  call Runner.Run(pargs)
enddef

export def Init()
  autocmd! User DbgDebugStartPre :call s:StartPre()
  autocmd! User DbgDebugStartPost :call s:StartPost()
  autocmd! User DbgDebugStopPre :call s:StopPre()
  autocmd! User DbgDebugStopPost :call s:StopPost()

  command -nargs=* -complete=file -bang DbgDebug call StartDebug(<bang>0, <f-args>)
  command DbgAsm call Runner.Asm()
  command DbgSource call Runner.Source()
  command DbgSave call Runner.SaveBrks()
enddef

export def DeInit()
  delcommand DbgDebug
enddef
