function vimext#gccdbg#Create(proto) abort
  let l:self = {
        \ "proto": a:proto,
        \ "cmd": "gdb",
        \ "GetCmd": function("s:GetCmd"),
        \ "SetConfig": function("s:SetConfig"),
        \ "Dispose": function("s:Dispose")
        \ }

  return l:self
endfunction

function s:SetConfig(self, prompt, proto) abort
  call a:prompt.Send(a:prompt, a:proto.Set . " " . "just-my-code 1")
endfunction

function s:GetCmd(self) abort
  let l:cmd = ["gdb"]
  let l:cmd += ['-quiet']
  let l:cmd += ['-iex', 'set mi-async on']
  let l:cmd += ['-iex', 'set pagination off']
  let l:cmd += ["--interpreter=" . a:self.proto.name]
  return l:cmd
endfunction

function s:Dispose(self)
endfunction
