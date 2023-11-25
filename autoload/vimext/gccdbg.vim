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
  endif
endfunction

function s:GetCmd(self, param) abort
  let l:cmd = ["gdb"]
  let l:cmd += ['-quiet']
  let l:cmd += ['-iex', 'set pagination off']
  let l:cmd += ['-iex', 'set mi-async on']
  let l:cmd += ['-tty', a:param.tty]
  let l:cmd += ["--interpreter=" . a:self.proto.name]
  return l:cmd
endfunction

function s:Dispose(self) abort
endfunction
