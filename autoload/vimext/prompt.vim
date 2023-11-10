"""
" refactor version of termdbug
"""

let s:mode = v:null
let s:dbg_name = v:null
let s:iface = v:null
let s:dbg_iface = v:null

let s:prompt_buf = 0
let s:dbg_channel = v:null
let s:running = 0
let s:output_stopped = 1

let s:pc_id = 30
let s:asm_id = 31

let s:dbg_win = v:null
let s:output_win = v:null
let s:source_win = v:null


function s:Highlight(init, old, new) abort
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    exe "hi " . default . "dbgPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    exe "hi " . default . "dbgPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif
endfunction

function s:InitHighlight() abort
  call sign_define('DbgPC', #{linehl: 'DbgPC'})
  call s:Highlight(1, '', &background)

  hi default dbgBreakpoint term=reverse ctermbg=red guibg=red
  hi default dbgBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction


function s:GetDbgByName(name)
  let s:netdbg_iface = {
        \ "GetCmd": function("s:NetDbgGetCmd"),
        \ "DecodeLine": function("s:NetDbgDecodeLine"),
        \ }

  if a:name == "gdb" && executable("gdb")
    return s:gdb_iface
  endif

  if a:name == "netcoredbg" && executable("netcoredbg")
    return s:netdbg_iface
  endif

  return v:null
endfunction

function s:InitIFace()
  let s:prompt_iface = {
        \ "Start": function("s:StartPrompt"),
        \ "Callback": function("s:PromptCallback"),
        \ "Interrupt": function("s:PromptInterrupt"),
        \ "Send": function("s:PromptSend"),
        \ 'Exit': function('s:PromptExit'),
        \ 'Out': function('s:PromptOut')
        \ }

  let s:term_iface = {
        \ "Start": function("s:StartTerm")
        \ }

  if !has('win32')
    let s:mode = 'terminal'
    let s:iface = s:term_iface
  else
    let s:mode = 'prompt'
    let s:iface = s:prompt_iface
  endif

  let s:dbg_name = "netcoredbg"
  let s:dbg_iface = s:GetDbgByName(s:dbg_name)

  if s:dbg_iface == v:null
    call vimext#logger#Error("failed to load debugger ".s:dbg_name)
  endif
endfunction

function s:InitChannel()
  let l:cmd = s:dbg_iface["GetCmd"]()

  let s:job = job_start(l:cmd, {
        \ 'exit_cb': s:iface["Exit"],
        \ 'out_cb': s:iface["Out"]
        \ })

  if job_status(s:job) != "run"
    call vimext#logger#Error('Failed to start '. l:cmd)
    return 0
  endif

  let s:dbg_channel = job_getchannel(s:job)
  return 1
endfunction

function s:Init() abort
  if !has('terminal')
    call vimext#logger#Warning("+terminal not enable in vim")
    return 0
  endif

  command -nargs=* -complete=file Dbgdebug call vimext#prompt#Start(<f-args>)

  call s:InitHighlight()
  call s:InitIFace()
  call s:InitChannel()
  call vimext#breakpoints#Init()

  if exists('#User#DbgDebugStartPre')
    doauto <nomodeline> User DbgDebugStartPre
  endif
endfunction

function vimext#prompt#Start(args) abort
  if s:dbg_win != 0
    call vimext#logger#Error('debugger already running, cannot run again')
    return
  endif

  call s:Init()

  call s:iface["Start"](a:args)

  if exists('#User#DbgDebugStartPost')
    doauto <nomodeline> User DbgDebugStartPost
  endif
endfunction

" netcoredbg debugger
function s:NetDbgGetCmd() abort
  let l:cmd = ["netcoredbg"]
  let l:cmd += ["--interpreter=cli"]
  let l:cmd += ["--", "dotnet"]
  return l:cmd
endfunction

function s:ProcessMsg(channel, text) abort
  let l:text = v:null

  if a:text == '(gdb)' || a:text == '^done' ||
        \ (a:text[0] == '&' && a:text !~ '^&"disassemble')
    return v:null
  endif

  if a:text =~ '^\^error,msg='
    let l:text = s:DecodeMessage(a:text[11:], v:false)
    if exists('s:evalexpr') && text =~ 'A syntax error in expression, near\|No symbol .* in current context'
      " Silently drop evaluation errors.
      unlet s:evalexpr
      return v:null
    endif
  elseif a:text[0] == '~'
    let l:text = s:DecodeMessage(a:text[1:], v:false)
  else
    return a:text
  endif

  return l:text
endfunction

" Prompt
function s:NewSourceWindow() abort
  if s:source_win != v:null
    return s:source_win
  endif

  vertical new
  let l:source_win = win_getid()
  execute (&columns / 2 - 1) . "wincmd |"

  return l:source_win
endfunction

function s:StartPrompt(args) abort
  let s:dbg_win = win_getid()
  let s:output_win = s:dbg_win
  let s:prompt_buf = bufnr('')

  call prompt_setprompt(s:prompt_buf, '(gdb)> ')
  set buftype=prompt
  call prompt_setcallback(s:prompt_buf, s:iface["Callback"])
  call prompt_setinterrupt(s:prompt_buf, s:iface["Interrupt"])

  execute $'au BufUnload <buffer={s:prompt_buf}> ++once ' ..
        \ 'call job_stop(s:job, ''kill'')'

  if has("win32")
    call s:PromptSend('set args '.a:args)
  endif
  startinsert
endfunction

function s:PromptExit(job, status) abort
  let s:running = 0
  exe 'bwipe! ' . s:prompt_buf
  unlet s:dbg_win

  if s:source_win != v:null
    unlet s:source_win
  endif

  if exists('#User#DbgDebugStopPost')
    doauto <nomodeline> User DbgDebugStopPost
  endif
endfunction

function s:PromptSend(cmd)
  if s:output_stopped == 0
    call vimext#logger#Info("Command Drop: ".a:cmd)
    return
  endif

  call vimext#logger#Info("PromptSend: ".a:cmd)
  " FIXME: NetCoreDbg cli mode will ignore first cmd, is a bug ?
  call ch_sendraw(s:dbg_channel, " ")
  call ch_sendraw(s:dbg_channel, a:cmd."\n")
endfunction

function vimext#prompt#SendCmd(msg)
  call s:PromptSend(a:msg)
endfunction

function s:LoadSource(fname, lnum) abort
  if !filereadable(a:fname)
    return
  endif

  let l:cwin = win_getid()
  if !win_gotoid(s:source_win)
    let s:source_win = s:NewSourceWindow()
  endif

  if expand("%:p") == a:fname
    call s:SignLine(a:fname, a:lnum)

    call win_gotoid(l:cwin)
    return
  endif

  exe 'e '.fnameescape(a:fname)
  call s:SignLine(a:fname, a:lnum)
  setlocal signcolumn=yes

  call win_gotoid(l:cwin)
endfunction

function s:NetDbgDecodeLine(msg) abort
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

  return l:info
endfunction

const s:NullRepl = 'XXXNULLXXX'
function s:DecodeMessage(quotedText, literal)
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

function s:ProcessStop(cmd)
  if s:running == 0
    return
  endif

  if exists('#User#DbgDebugStopPre')
    doauto <nomodeline> User DbgDebugStopPre
  endif

  call vimext#breakpoints#DeInit()
endfunction

function s:PromptOut(channel, msg) abort
  call vimext#logger#Info("PromptOut ".a:msg)

  let l:msg = s:ProcessMsg(a:channel, a:msg)
  if l:msg == v:null
    return
  endif

  let l:info = s:dbg_iface["DecodeLine"](l:msg)

  if info[0] == 1 " hit breakpoints
    let s:output_stopped = 1
    call s:LoadSource(info[2], info[3])

  elseif info[0] == 3 " running
    let s:running = 1
    let s:output_stopped = 0

  elseif info[0] == 2 " exit normally
    let s:output_stopped = 1

  elseif info[0] == 4 " user set breakpoint
    let s:output_stopped = 1

  elseif info[0] == 5 " exit end stepping range
    call s:LoadSource(info[1], info[2])
    let s:output_stopped = 1

  else
    call win_gotoid(s:output_win)
    call append(line('$') - 1, l:msg)
    set modified
  endif
endfunction

function s:SignLine(fname, lnum) abort
  exe a:lnum
  normal! zv

  call sign_unplace('DbgDebug', #{id: s:pc_id})
  call sign_place(s:pc_id, 'DbgDebug', 'DbgPC', a:fname, #{lnum: a:lnum, priority: 110})
endfunction

function s:PromptCallback(cmd) abort
  if s:output_stopped == 0
    return
  endif

  if a:cmd == "q" || a:cmd == "quit"
    call s:ProcessStop(a:cmd)
  endif

  call s:PromptSend(a:cmd)
endfunction

function s:PromptInterrupt() abort
  call vimext#logger#Info("PromptInterrupt")
endfunction

" Term
let s:term_buf = 0

function s:StartTerm() abort
  call vimext#logger#Info("StartTerm")
endfunction

function s:TermSend(cmd) abort
  call term_sendkeys(s:term_buf, a:cmd . "\r")
endfunction
