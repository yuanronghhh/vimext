function vimext#gccdbg#Create(proto) abort
  let l:self = {
        \ "proto": a:proto,
        \ "name": "gdb",
        \ "GetCmd": function("s:GetCmd"),
        \ "SetConfig": function("s:SetConfig"),
        \ "Dispose": function("s:Dispose")
        \ }

  return l:self
endfunction

function s:SetConfig(self, prompt, proto) abort
  if has("win32")
    call a:prompt.Send(a:prompt, a:proto.Set . " new-console on")
    call a:prompt.Send(a:prompt, a:proto.Set . " print pretty on")
    call a:prompt.Send(a:prompt, a:proto.Set . " breakpoint pending on")
  else
    call a:prompt.Send(a:prompt, "set print pretty on")
    call a:prompt.Send(a:prompt, "set breakpoint pending on")
  endif

endfunction

function vimext#gccdbg#FilterStart(term) abort
  let try_count = 0

  while 1
    if !a:term.Running(a:term)
      call vimext#logger#Error('Exited unexpectedly: '. join(a:cmd, " "))
      return 0
    endif

    for l:lnum in range(1, 200)
      let l:lstr = a:term.GetLine(a:term, l:lnum)
      if l:lstr =~ 'startupdone'
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

function s:GetCmd(self, oterm) abort
  let l:tty = a:oterm.tty
  let l:protoname = a:self.proto.name

  return s:GetGccCmd(l:protoname, l:tty)
endfunction

function s:GetGccCmd(protoname, tty) abort
  let l:cmd = ["gdb"]
  let l:cmd += ['-quiet']
  let l:cmd += ['-iex', 'set pagination off']
  let l:cmd += ['-iex', 'set mi-async on']

  if a:protoname == "mi2" && has("win32")
    let l:cmd += ['--interpreter=mi2']
  else
    let l:cmd += ['-tty', a:tty]
  endif

  return l:cmd
endfunction

function s:Dispose(self) abort
endfunction
