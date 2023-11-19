"""
" refactor version of termdbug
"""
let s:output_stopped = 1 " lock for callback
let s:self = v:null

function vimext#prompt#Highlight(init, old, new) abort
  let default = a:init ? 'default ' : ''
  if a:new ==# 'light' && a:old !=# 'light'
    exe "hi " . default . "DbgPC term=reverse ctermbg=lightblue guibg=lightblue"
  elseif a:new ==# 'dark' && a:old !=# 'dark'
    exe "hi " . default . "DbgPC term=reverse ctermbg=darkblue guibg=darkblue"
  endif
endfunction

function vimext#prompt#InitHighlight() abort
  call vimext#prompt#Highlight(1, '', &background)
endfunction

function vimext#prompt#InitChannel(self) abort
  let l:cmd = a:self.dbg.GetCmd(a:self.dbg)
  let l:job = job_start(l:cmd, {
        \ "exit_cb": a:self.HandleExit,
        \ "out_cb": a:self.HandleOutput
        \ })

  if job_status(l:job) != "run"
    call vimext#logger#Error('Failed to start:'. join(l:cmd, ' '))
    return 0
  endif

  let a:self.job = l:job
  let a:self.dbg_channel = job_getchannel(l:job)
  return 1
endfunction

function s:StartPrompt(self) abort
  let a:self.dbg_win = win_getid()
  let a:self.prompt_buf = bufnr('%')
  let a:self.output_win = a:self.dbg_win

  call prompt_setprompt(a:self.prompt_buf, '(gdb) ')
  setlocal buftype=prompt
  call prompt_setcallback(a:self.prompt_buf, a:self["Callback"])
  call prompt_setinterrupt(a:self.prompt_buf, a:self["Interrupt"])

  startinsert
endfunction

function s:PromptSend(self, cmd) abort
  if s:output_stopped == 0
    call vimext#logger#Warning("Command Drop: ".a:cmd)
    return
  endif

  "call vimext#logger#Info(a:cmd)
  call ch_sendraw(a:self.dbg_channel, a:cmd."\n")
endfunction


function vimext#prompt#CreateAsmWin()
  let l:win = vimext#buffer#NewWindow("asm")

  setlocal nowrap
  setlocal number
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal signcolumn=no
  setlocal modifiable

  return l:win
endfunction

function vimext#prompt#Asm(self)
  if vimext#buffer#WinExists(a:self.asm_win)
    return v:false
  endif

  let a:self.asm_win = vimext#prompt#CreateAsmWin()
  return v:true
endfunction

function vimext#prompt#LoadSource(self, fname, lnum) abort
  let l:cwin = win_getid()
  if !filereadable(a:fname)
    call vimext#logger#Warning("file not readable " . a:fname)
    return
  endif

  if a:self.source_win == v:null
    let a:self.source_win = vimext#buffer#NewWindow("source")
  endif
  call win_gotoid(a:self.source_win)

  if vimext#buffer#GetNameByWinID(a:self.source_win) != a:fname
    execute "edit ".a:fname
    let a:self.source_buff = bufnr("%")
    setlocal signcolumn=yes
  endif

  call vimext#sign#Line(a:fname, a:lnum)
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
  "call vimext#logger#Info("PromptInterrupt")

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
        \ "asm_win": 31,
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
        \ 'HandleExit': get(a:funcs, "HandleExit", v:null),
        \ "HandleInput": get(a:funcs, "HandleInput", v:null),
        \ 'HandleOutput': get(a:funcs, "HandleOutput", v:null),
        \ "Send": function("s:PromptSend"),
        \ "Dispose": function("s:Dispose"),
        \ }

  if !has('terminal')
    call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif

  call vimext#prompt#InitHighlight()
  if vimext#prompt#InitChannel(l:self) == 0
    return v:null
  endif
  let s:self = l:self

  return l:self
endfunction

function vimext#prompt#GetSouceWinPath(self) abort
  return vimext#buffer#GetNameByWinID(a:self.source_win)
endfunction

function vimext#prompt#SetOutputState(self, state) abort
  let s:output_stopped = a:state
endfunction

function s:Dispose(self) abort
  if a:self == v:null
    return
  endif

  let a:self.running = 0

  if a:self.source_win != v:null
    call vimext#buffer#WipeWin(a:self.source_win)
    unlet a:self.source_win
  endif

  call vimext#buffer#Wipe(a:self.prompt_buf)
  call job_stop(a:self.job, "kill")

  unlet a:self.output_win
  unlet a:self.dbg_win
  unlet a:self.prompt_buf
  let s:self = v:null
endfunction
