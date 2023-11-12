"""
" refactor version of termdbug
"""
let s:output_stopped = 1 " lock for callback
let s:self = v:null
let s:pc_id = 30


function s:Highlight(init, old, new) abort
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    exe "hi " . default . "DbgPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    exe "hi " . default . "DbgPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif

  hi default debugBreakpoint term=reverse ctermbg=red guibg=red
  hi default debugBreakpointDisabled term=reverse ctermbg=gray guibg=gray
endfunction

function s:InitHighlight() abort
  call sign_define('DbgPC', #{linehl: 'DbgPC'})
  call s:Highlight(1, '', &background)
endfunction

function s:GotoWin(win_id)
  if !win_gotoid(a:win_id)
    call vimext#logger#Error("failed")
  endif
endfunction

function s:InitChannel(self) abort
  let l:cmd = a:self.dbg.GetCmd(a:self.dbg)

  let l:job = job_start(l:cmd, {
        \ "exit_cb": a:self.Exit,
        \ "out_cb": a:self.Out
        \ })

  if job_status(l:job) != "run"
    call vimext#logger#Error('Failed to start '. l:cmd)
    return 0
  endif

  let a:self.job = l:job
  let a:self.dbg_channel = job_getchannel(l:job)
  return 1
endfunction

function vimext#prompt#Interrupt() abort
endfunction

function s:StartPrompt(self) abort
  call vimext#logger#Info("StartPrompt")

  let a:self.dbg_win = win_getid()
  let a:self.prompt_buf = bufnr('%')
  let a:self.output_win = a:self.dbg_win

  set modified
  set buftype=prompt
  call prompt_setprompt(a:self.prompt_buf, '(gdb)> ')
  call prompt_setcallback(a:self.prompt_buf, a:self["Callback"])
  call prompt_setinterrupt(a:self.prompt_buf, a:self["Interrupt"])

  execute 'au BufUnload <buffer=' . a:self.prompt_buf .'> ++once ' ..
        \ 'call job_stop(' . a:self.job . ', ''kill'')'

  startinsert
endfunction

function s:PromptExit(job, status) abort
  call vimext#logger#Info("PromptExit")

  if s:self != v:null
    let s:self.running = 0
    unlet s:self.dbg_win

    if s:self.source_win != v:null
      unlet s:self.source_win
    endif
  endif

  exe 'bwipe! ' . s:self.prompt_buf

  if exists('#User#DbgDebugStopPost')
    doauto <nomodeline> User DbgDebugStopPost
  endif
endfunction

function s:PromptSend(self, cmd) abort
  call vimext#logger#Info("PromptSend ".a:cmd)

  if s:output_stopped == 0
    call vimext#logger#Info("Command Drop: ".a:cmd)
    return
  endif

  call ch_sendraw(a:self.dbg_channel, a:cmd."\n")
endfunction

function s:LoadSource(self, fname, lnum) abort
  if !filereadable(a:fname)
    return
  endif

  let l:cwin = win_getid()

  if a:self.source_win == v:null
    let a:self.source_win = vimext#debug#NewWindow("source")
  endif

  if expand("%:p") == a:fname
    call s:SignLine(a:fname, a:lnum)
    return
  endif

  call win_gotoid(a:self.source_win)
  exe 'e '.a:fname
  call s:SignLine(a:fname, a:lnum)
  setlocal signcolumn=yes

  call win_gotoid(l:cwin)
endfunction

function s:SignLine(fname, lnum) abort
  exe a:lnum
  normal! zv

  call sign_unplace('DbgDebug', #{id: s:pc_id})
  call sign_place(s:pc_id, 'DbgDebug', 'DbgPC', a:fname, #{lnum: a:lnum, priority: 110})
endfunction

function s:ProcessStop(cmd)
  if s:self.running == 0
    return a:cmd
  endif

  if exists('#User#DbgDebugStopPre')
    doauto <nomodeline> User DbgDebugStopPre
  endif

  return s:self.proto.Interrupt
endfunction

function s:PrintOutput(self, msg) abort
  let l:cwin = win_getid()

  call win_gotoid(a:self.output_win)
  call append(line('$') - 1, a:msg)

  call win_gotoid(l:cwin)
endfunction

function s:ProcessMsg(channel, text) abort
  let l:text = v:null

  if a:text =~ '(gdb)'
        \ || a:text == '^done'
        \ || (a:text[0] == '&' && a:text !~ '^&"disassemble')
    return v:null
  endif

  if a:text =~ '^\^error,msg='
    let l:text = vimext#debug#DecodeMessage(a:text[11:], v:false)
    if exists('s:evalexpr') && text =~ 'A syntax error in expression, near\|No symbol .* in current context'
      " Silently drop evaluation errors.
      unlet s:evalexpr
      return v:null
    endif
  elseif a:text[0] == '~'
    let l:text = vimext#debug#DecodeMessage(a:text[1:], v:false)
  else
    return a:text
  endif

  return l:text
endfunction

function s:PromptOut(channel, msg) abort
  let l:msg = s:ProcessMsg(a:channel, a:msg)
  if l:msg == v:null
    return
  endif

  let l:info = s:self.proto.DecodeLine(l:msg)
  call vimext#logger#Info(l:info)

  if info[0] == 1 " hit breakpoint
    call s:LoadSource(s:self, info[1], info[2])
    let s:output_stopped = 1

  elseif info[0] == 3 " running
    let s:output_stopped = 0

  elseif info[0] == 2 " exit normally
    let s:output_stopped = 1

  elseif info[0] == 4 " user set breakpoint
    "call vimext#breakpoint#Insert(info[1], 1)
    let s:output_stopped = 1

  elseif info[0] == 5 " exit end stepping range
    call s:LoadSource(s:self, info[1], info[2])
    let s:output_stopped = 1

  elseif info[0] == 7 " filter useless msg

  else
    call s:PrintOutput(s:self, a:msg)
  endif
endfunction

" prompt
function s:PromptCallback(cmd) abort
  if s:output_stopped == 0
    return
  endif

  let l:cmd = a:cmd
  if a:cmd == "q" || a:cmd == "quit"
    let l:cmd = s:ProcessStop(a:cmd)
  endif

  call s:PromptSend(s:self, l:cmd)
endfunction

function s:PromptInterrupt() abort
  call vimext#logger#Info("PromptInterrupt")

  if s:pid == 0
    call vimext#logger#Error('Cannot interrupt, not find a process ID')
    return
  endif

  call debugbreak(s:prompt_pid)
endfunction

function vimext#prompt#Create(dbg, proto) abort
  let l:self = {
        \ "dbg": a:dbg,
        \ "proto": a:proto,
        \ "mode": v:null,
        \ "asm_id": 31,
        \ "dbg_channel": v:null,
        \ "job": v:null,
        \ "running": 0,
        \ "dbg_win": v:null,
        \ "output_win": v:null,
        \ "source_win": v:null,
        \ "prompt_pid": 0,
        \ "prompt_buf": 0,
        \ "Start": function("s:StartPrompt"),
        \ "Callback": function("s:PromptCallback"),
        \ "Interrupt": function("s:PromptInterrupt"),
        \ "Send": function("s:PromptSend"),
        \ 'Exit': function('s:PromptExit'),
        \ 'Out': function('s:PromptOut'),
        \ "Dispose": function("s:Dispose")
        \ }

  if !has('terminal')
    call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  call s:InitHighlight()
  if s:InitChannel(l:self) == 0
    return v:null
  endif
  call s:StartPrompt(l:self)

  let s:self = l:self

  return l:self
endfunction

function s:Dispose(self)
endfunction
