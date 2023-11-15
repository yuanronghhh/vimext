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

  hi default dbgSignOn term=reverse ctermbg=red guibg=red
  hi default dbgSignOff term=reverse ctermbg=gray guibg=gray
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

function vimext#prompt#RemoveSign(self, buff, id) abort
  call sign_undefine('DbgSign'.a:id)
  call sign_unplace("DbgDebug", {
        \ "buffer": a:buff,
        \ "id": a:id})
endfunction

function vimext#prompt#PlaceSign(self, filename, linenum, id, text, flag)
  let l:hiName = "dbgSignOn"
  if a:flag == 0
    let l:hiName = "dbgSignOff"
  endif

  call sign_define('DbgSign'.a:id, {
        \ "text": a:text,
        \ "texthl": l:hiName})

  call sign_place(a:id,
        \ "DbgDebug",
        \ "DbgSign" . a:id,
        \ a:filename,
        \ #{lnum: a:linenum, priority: 110})
endfunction

function vimext#prompt#SignLine(fname, lnum, clean) abort
  exe a:lnum
  normal! zv

  if a:clean == 1
    call sign_unplace('DbgDebug', #{id: s:pc_id})
  endif

  call sign_place(s:pc_id, 'DbgDebug', 'DbgPC', a:fname, #{lnum: a:lnum, priority: 110})
endfunction

function s:InitChannel(self) abort
  let l:cmd = a:self.dbg.GetCmd(a:self.dbg)

  let l:job = job_start(l:cmd, {
        \ "exit_cb": a:self.HandleExit,
        \ "out_cb": a:self.HandleOutput
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
  let a:self.dbg_win = win_getid()
  let a:self.prompt_buf = bufnr('%')
  let a:self.output_win = a:self.dbg_win

  set modified
  set buftype=prompt
  call prompt_setprompt(a:self.prompt_buf, '(gdb) ')
  call prompt_setcallback(a:self.prompt_buf, a:self["Callback"])
  call prompt_setinterrupt(a:self.prompt_buf, a:self["Interrupt"])

  startinsert
endfunction

function s:PromptSend(self, cmd) abort
  if s:output_stopped == 0
    call vimext#logger#Warning("Command Drop: ".a:cmd)
    return
  endif

  call ch_sendraw(a:self.dbg_channel, a:cmd."\n")
endfunction

function vimext#prompt#LoadSource(self, fname, lnum) abort
  let l:cwin = win_getid()
  if !filereadable(a:fname)
    return
  endif

  if a:self.source_win == v:null
    let a:self.source_win = vimext#debug#NewWindow("source")
  endif
  call win_gotoid(a:self.source_win)

  if a:self.source_path != a:fname
    exe 'edit '.a:fname
    setlocal signcolumn=yes
    let a:self.source_path = a:fname
  endif

  call vimext#prompt#SignLine(a:fname, a:lnum, 1)
  call win_gotoid(l:cwin)
endfunction

function vimext#prompt#PrintOutput(self, msg) abort
  let l:cwin = win_getid()

  call win_gotoid(a:self.output_win)
  call append(line('$') - 1, a:msg)

  call win_gotoid(l:cwin)
endfunction

" prompt
function s:PromptCallback(cmd) abort
  if s:output_stopped == 0
    return
  endif

  let l:cmd = s:self.HandleInput(a:cmd)
  if l:cmd == v:null
    return
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

function vimext#prompt#Create(dbg, funcs) abort
  let l:self = {
        \ "dbg": a:dbg,
        \ "mode": v:null,
        \ "asm_id": 31,
        \ "dbg_channel": v:null,
        \ "job": v:null,
        \ "running": 0,
        \ "dbg_win": v:null,
        \ "output_win": v:null,
        \ "source_win": v:null,
        \ "source_path": v:null,
        \ "prompt_pid": 0,
        \ "prompt_buf": 0,
        \ "Start": function("s:StartPrompt"),
        \ "Callback": function("s:PromptCallback"),
        \ "Interrupt": function("s:PromptInterrupt"),
        \ 'HandleExit': get(a:funcs, "HandleExit", v:null),
        \ "HandleInput": get(a:funcs, "HandleInput", v:null),
        \ 'HandleOutput': get(a:funcs, "HandleOutput", v:null),
        \ "Send": function("s:PromptSend"),
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
  let s:self = l:self

  return l:self
endfunction

function vimext#prompt#GetSourcePath(self)
  return a:self.source_path
endfunction

function vimext#prompt#SetOutputState(self, state) abort
  let s:output_stopped = a:state
endfunction

function s:Dispose(self)
  let l:was_buf = v:null

  if a:self != v:null
    let a:self.running = 0

    if a:self.source_win != v:null
      call win_gotoid(a:self.source_win)
      let l:was_buf = bufnr()

      unlet a:self.source_win
    endif

    set nomodified
    set buftype=
    call prompt_setprompt(a:self.prompt_buf, '')

    exe 'bwipe! ' . a:self.prompt_buf
    call job_stop(a:self.job, "kill")

    unlet a:self.dbg_win
    unlet a:self.prompt_buf
    unlet a:self.output_win
  endif
endfunction
