function vimext#gccdbg#Create(proto) abort
  let self = {
        \ "proto": a:proto,
        \ "name": "gdb",
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

function vimext#gccdbg#FilterStart(term) abort
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

  return s:GetGccCmd(protoname, tty, a:args)
endfunction

function s:GetGccCmd(protoname, tty, args) abort
  let cmd = ["gdb"]
  let cmd += ['-quiet']
  let cmd += ['-iex', 'set pagination off']
  let cmd += ['-iex', 'set mi-async on']

  if a:protoname == "mi2" && has("win32")
    let cmd += ['--interpreter=mi2']
  else
    let cmd += ['-tty', a:tty]
  endif
  let cmd += a:args

  return cmd
endfunction

function s:Dispose(self) abort
endfunction
