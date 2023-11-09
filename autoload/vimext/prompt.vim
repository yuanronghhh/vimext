let s:mode = ""
let s:iface = {}
let s:dbg_iface = {}

let s:prompt_buf = 0
let s:channel = v:null
let s:running = 0
let s:output_stopped = 0

let s:pc_id = 12
let s:asm_id = 13
let s:break_id = 14  " copy from termdebug

let s:dbg_win = v:null
let s:output_win = v:null
let s:source_win = v:null

let s:keepcpo = &cpo
set cpo&vim

function s:Highlight(init, old, new)
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    exe "hi " . default . "debugPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    exe "hi " . default . "debugPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif
endfunction

function s:InitHighlight()
  call s:Highlight(1, '', &background)
  hi default debugBreakpoint term=reverse ctermbg=red guibg=red
  hi default debugBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction

function s:Init() abort
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

  let s:netdbg_iface = {
        \ "GetCmd": function("s:NetDbgGetCmd"),
        \ "DecodeLine": function("s:NetDbgDecodeLine"),
        \ "ProcessMsg": function("s:NetDbgProcessMsg")
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

  call sign_define('debugPC', #{linehl: 'debugPC'})
endfunction

function vimext#prompt#Start(args) abort
  call s:Init()

  if s:dbg_win != 0
    call vimext#logger#Error('debugger already running, cannot run again')
    return
  endif

  call s:iface["Start"](a:args)
endfunction

" netcoredbg debugger
function s:NetDbgGetCmd()
  let l:cmd = ["netcoredbg"]
  let l:cmd += ["--interpreter=cli"]
  let l:cmd += ["--", "dotnet"]

  return l:cmd
endfunction

function s:NetDbgProcessMsg(channel, text)
  if a:text == '(gdb) ' || a:text == '^done' ||
        \ (a:text[0] == '&' && a:text !~ '^&"disassemble')
    return
  endif

  return a:text
endfunction

" Prompt
function s:StartPrompt(args, ...) abort
  let s:dbg_win = win_getid()
  let s:output_win = s:dbg_win
  let s:prompt_buf = bufnr('')

  set buftype=prompt
  call prompt_setprompt(s:prompt_buf, 'debug> ')
  call prompt_setcallback(s:prompt_buf, s:iface["Callback"])
  call prompt_setinterrupt(s:prompt_buf, s:iface["Interrupt"])

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

  exe $'au BufUnload <buffer={s:prompt_buf}> ++once ' ..
        \ 'call job_stop(s:job, ''kill'')'

  let s:channel = job_getchannel(s:job)
  if has("win32")
    call s:PromptSend('set args '.a:args)
  endif
endfunction

function s:PromptExit(job, status) abort
  call vimext#logger#Info("PromptExit ".a:job." + ".a:status)
endfunction

function s:PromptSend(cmd) abort
  call ch_sendraw(s:channel, a:cmd . "\n")
endfunction

function s:LoadSource(fname, lnum) abort
  if !win_gotoid(s:source_win)
    vertical new
    let s:source_win = win_getid()
  endif

  if !filereadable(a:fname)
    return
  endif

  exe 'edit '.fnameescape(a:fname)
  exe a:lnum
  normal! zv
  call s:SignBreakpoint(a:fname, a:lnum)
  setlocal signcolumn=yes
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

function s:PromptOut(channel, msg) abort
  let l:info = s:dbg_iface["DecodeLine"](a:msg)

  call vimext#logger#Info(l:info)

  if info[0] == 1 " hit breakpoints
    let l:output_stopped = 1
    let l:c_win = win_getid()
    call s:LoadSource(info[2], info[3])
    call win_gotoid(l:c_win)
  elseif info[0] == 2 " exit normally
    let l:output_stopped = 1
  elseif info[0] == 5 " exit normally
    call s:LoadSource(info[1], info[2])
    let l:output_stopped = 1
  endif

  call win_gotoid(s:output_win)
  call append(line('$') - 1, a:msg)
  "set modified
endfunction

function s:SignBreakpoint(fname, lnum) abort
  call sign_unplace('TermDebug', #{id:
        \ s:pc_id})
  call sign_place(s:pc_id, 'TermDebug', 'debugPC',
        \ a:fname, #{lnum: a:lnum, priority: 110})
endfunction

function s:PromptCallback(text) abort
  call s:iface["Send"](a:text)
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

let &cpo = s:keepcpo
unlet s:keepcpo
