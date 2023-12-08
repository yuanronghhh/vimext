vim9script

import "./logger.vim" as Logger
import "./runner.vim" as Runner

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

  var rmanager = Runner.Manager.new(lang, pargs)
  if rmanager == v:null
    return
  endif

  # call rmanager.Run(pargs)
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
