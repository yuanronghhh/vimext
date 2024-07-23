function vimext#gdb#Create(proto) abort
  let self = {
        \ "proto": a:proto,
        \ "name": "gdb",
        \ "mode": 1,
        \ "GetCmd": function("s:GetCmd"),
        \ "SetConfig": function("s:SetConfig"),
        \ "Dispose": function("s:Dispose")
        \ }

  return self
endfunction

function s:SetConfig(self, prompt, proto) abort
  if has("win32")
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, "new-console on"))
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, "print pretty on"))
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, "breakpoint pending on"))
  else
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, "breakpoint pending on"))
  endif

endfunction

function vimext#gdb#FilterStart(term) abort
  let try_count = 0

  while 1
    if !a:term.Running(a:term)
      :call vimext#logger#Error('Exited unexpectedly: '. join(a:cmd, " "))
      return 0
    endif

    for lnum in range(1, 200)
      let lstr = a:term.GetLine(a:term, lnum)
      if lstr =~ 'startupdone'
        let try_count = 9999
        break
      endif
    endfor
    let try_count += 1
    if try_count > 300
      " done or give up after five seconds
      break
    endif
    sleep 10m
  endwhile
endfunction

function s:GetCmd(self, oterm, args) abort
  let tty = a:oterm.tty
  let protoname = a:self.proto.name

  return s:GetGdbCmd(protoname, tty, a:args)
endfunction

function s:GetGdbCmd(protostr, tty, args) abort
  let protoname = a:protostr
  let cmd = ["gdb"]
  let cmd += ['-quiet']

  if has("win32")
    let cmd += ['--interpreter=' . protoname]
  endif

  if a:tty isnot v:null
    " tty should set before execute
    let cmd += ['-tty', a:tty]
  endif

  let cmd += ['-iex', 'set index-cache on']
  let cmd += ['-iex', 'set pagination off']
  let cmd += ['-iex', 'set mi-async on']
  let cmd += ['-iex', 'set debuginfod enabled off']

  if len(a:args) == 1
    let a:args[0] = vimext#debug#DecodeFilePath(a:args[0])
  endif
  let cmd += a:args

  return cmd
endfunction

function s:Dispose(self) abort
endfunction
