let s:mode = ""
let s:iface = {}
let s:dbg_iface = {}

let s:prompt_buf = 0
let s:dbg_channel = v:null
let s:running = 0
let s:output_stopped = 0

let s:pc_id = 30
let s:asm_id = 31
let s:break_id = 32  " copy from termdebug

let s:dbg_win = v:null
let s:output_win = v:null
let s:source_win = v:null

function vimext#prompt#InitHighlight() abort
  call sign_define('DbgPC', #{linehl: 'DbgPC'})

  hi DbgPC term=reverse ctermbg=darkblue guibg=darkblue
  hi default debugBreakpoint term=reverse ctermbg=red guibg=red
  hi default debugBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction

function vimext#prompt#Init() abort
  command -nargs=* -complete=file -bang DbgDebug echoerr s:err
  command -nargs=+ -complete=file -bang DbgDebugCommand echoerr s:err

  let s:prompt_iface = {
        \ "Start": function("vimext#prompt#StartPrompt"),
        \ "Callback": function("vimext#prompt#PromptCallback"),
        \ "Interrupt": function("vimext#prompt#PromptInterrupt"),
        \ "Send": function("vimext#prompt#PromptSend"),
        \ 'Exit': function('vimext#prompt#PromptExit'),
        \ 'Out': function('vimext#prompt#PromptOut')
        \ }

  let s:term_iface = {
        \ "Start": function("vimext#prompt#StartTerm")
        \ }

  let s:netdbg_iface = {
        \ "GetCmd": function("vimext#prompt#NetDbgGetCmd"),
        \ "DecodeLine": function("vimext#prompt#NetDbgDecodeLine"),
        \ "ProcessMsg": function("vimext#prompt#NetDbgProcessMsg")
        \ }

  if !has('terminal')
    return
  endif

  if !has('win32')
    let s:mode = 'terminal'
    let s:iface = s:term_iface
  else
    let s:mode = 'prompt'
    let s:iface = s:prompt_iface
  endif

  if executable("netcoredbg")
    let s:dbg_iface = s:netdbg_iface
  endif

  call vimext#prompt#InitHighlight()
endfunction

function vimext#prompt#Start(args) abort
  call vimext#prompt#Init()

  if s:dbg_win != 0
    call vimext#logger#Error('debugger already running, cannot run again')
    return
  endif

  call s:iface["Start"](a:args)
endfunction

" netcoredbg debugger
function vimext#prompt#NetDbgGetCmd() abort
  let l:cmd = ["netcoredbg"]
  let l:cmd += ["--interpreter=cli"]
  let l:cmd += ["--", "dotnet"]

  return l:cmd
endfunction

function vimext#prompt#NetDbgProcessMsg(channel, text) abort
  if a:text == '(dbg) ' || a:text == '^done' ||
        \ (a:text[0] == '&' && a:text !~ '^&"disassemble')
    return
  endif

  return a:text
endfunction

" Prompt
function vimext#prompt#NewSourceWindow() abort
  let l:c_win = win_getid()

  if s:source_win != v:null
    return s:source_win
  endif

  vertical new
  let s:source_win = win_getid()
  exe (&columns / 2 - 1) . "wincmd |"

  call win_gotoid(l:c_win)
endfunction

function vimext#prompt#StartPrompt(args, ...) abort

  let s:dbg_win = win_getid()
  let s:output_win = s:dbg_win
  let s:prompt_buf = bufnr('%')

  set buftype=prompt
  call prompt_setprompt(s:prompt_buf, '(dbg)> ')
  call prompt_setcallback(s:prompt_buf, s:iface["Callback"])
  call prompt_setinterrupt(s:prompt_buf, s:iface["Interrupt"])

  call vimext#prompt#NewSourceWindow()

  let l:cmd = s:dbg_iface["GetCmd"]()
  let s:job = job_start(l:cmd, {
        \ 'exit_cb': s:iface["Exit"],
        \ 'out_cb': s:iface["Out"]
        \ })

  if job_status(s:job) != "run"
    call vimext#logger#Error('Failed to start '. l:cmd)
    exe 'bwipe! ' . s:prompt_buf
    return
  endif

  execute $'au BufUnload <buffer={s:prompt_buf}> ++once ' ..
        \ 'call job_stop(s:job, ''kill'')'

  let s:dbg_channel = job_getchannel(s:job)
  if has("win32")
    call vimext#prompt#PromptSend('set args '.a:args)
  endif
endfunction

function vimext#prompt#PromptExit(job, status) abort
  call vimext#logger#Info("PromptExit ".a:job." + ".a:status)
endfunction

function vimext#prompt#PromptSend(cmd)
  call ch_sendraw(s:dbg_channel, a:cmd."\n")
endfunction

function vimext#prompt#LoadSource(fname, lnum) abort
  if !win_gotoid(s:source_win)
    call vimext#prompt#NewSourceWindow()
  endif

  if !filereadable(a:fname)
    return
  endif

  if expand("%:p") == a:fname
    call vimext#prompt#SignLine(a:fname, a:lnum)
    return
  endif

  if &modified
    execute 'split ' . fnameescape(a:fname)
    let s:sourcewin = win_getid()
  endif

  exe 'e '.fnameescape(a:fname)
  call vimext#prompt#SignLine(a:fname, a:lnum)
  setlocal signcolumn=yes
  set nomodified
endfunction

function vimext#prompt#NetDbgDecodeLine(msg) abort
  call vimext#logger#Info("NetDbgDecodeLine ".a:msg)
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

  if a:msg =~ '^stopped, reason: exited, exit-code: 0'
    let l:info[0] = 2
    return l:info
  endif

  if a:msg =~ '^running'
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

  return l:info
endfunction

function vimext#prompt#DecodeMessage(quotedText, literal)
  if a:quotedText[0] != '"'
    call s:Echoerr('DecodeMessage(): missing quote in ' . a:quotedText)
    return
  endif
  let msg = a:quotedText
        \ ->substitute('^"\|[^\\]\zs".*', '', 'g')
        \ ->substitute('\\"', '"', 'g')
        "\ multi-byte characters arrive in octal form
        "\ NULL-values must be kept encoded as those break the string otherwise
        \ ->substitute('\\000', vimext#prompt#NullRepl, 'g')
        \ ->substitute('\\\o\o\o', {-> eval('"' .. submatch(0) .. '"')}, 'g')
        "\ Note: GDB docs also mention hex encodings - the translations below work
        "\       but we keep them out for performance-reasons until we actually see
        "\       those in mi-returns
        "\ \ ->substitute('\\0x\(\x\x\)', {-> eval('"\x' .. submatch(1) .. '"')}, 'g')
        "\ \ ->substitute('\\0x00', vimext#prompt#NullRepl, 'g')
        \ ->substitute('\\\\', '\', 'g')
        \ ->substitute(vimext#prompt#NullRepl, '\\000', 'g')
  if !a:literal
    return msg
          \ ->substitute('\\t', "\t", 'g')
          \ ->substitute('\\n', '', 'g')
  else
    return msg
  endif
endfunction


function vimext#prompt#PromptOut(channel, msg) abort
  let l:msg = s:dbg_iface["ProcessMsg"](a:channel, a:msg)
  let l:c_win = win_getid()
  let l:info = s:dbg_iface["DecodeLine"](l:msg)

  if info[0] == 1 " hit breakpoints
    let l:output_stopped = 1
    call vimext#prompt#LoadSource(info[2], info[3])
  elseif info[0] == 2 " exit normally
    let l:output_stopped = 1
  elseif info[0] == 5 " exit end stepping range
    call vimext#prompt#LoadSource(info[1], info[2])
    let l:output_stopped = 1
  endif

  call win_gotoid(s:output_win)
  call append(line('$') - 1, l:msg)
  set modified

  call win_gotoid(l:c_win)
endfunction

function vimext#prompt#SignLine(fname, lnum) abort
  exe a:lnum
  normal! zv

  call sign_unplace('DbgDebug', #{id: s:pc_id})
  call sign_place(s:pc_id, 'DbgDebug', 'DbgPC', a:fname, #{lnum: a:lnum, priority: 110})
endfunction

function vimext#prompt#PromptCallback(text) abort
  call vimext#prompt#PromptSend(a:text)
endfunction

function vimext#prompt#PromptInterrupt() abort
  call vimext#logger#Info("PromptInterrupt")
endfunction

" Term
let s:term_buf = 0

function vimext#prompt#StartTerm() abort
  call vimext#logger#Info("StartTerm")
endfunction

function vimext#prompt#TermSend(cmd) abort
  call term_sendkeys(s:term_buf, a:cmd . "\r")
endfunction
