function vimext#netcoredbg#Create(proto) abort
  let l:self = {
        \ "proto": a:proto,
        \ "name": "netcoredbg",
        \ "GetCmd": function("s:GetCmd"),
        \ "SetConfig": function("s:SetConfig"),
        \ "Dispose": function("s:Dispose")
        \ }

  return l:self
endfunction

function s:SetConfig(self, prompt, proto) abort
  call a:prompt.Send(a:prompt, a:proto.Set . " " . "just-my-code 1")
  "call a:prompt.Send(a:prompt, a:proto.Set . " " . "step-filtering 1")
endfunction

function s:GetCmd(self) abort
  let l:cmd = ["netcoredbg"]
  let l:cmd += ["--interpreter=" . a:self.proto.name]
  let l:cmd += ["--", "dotnet"]
  return l:cmd
endfunction

function s:Dispose(self) abort
endfunction
