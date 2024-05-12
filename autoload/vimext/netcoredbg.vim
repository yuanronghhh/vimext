function vimext#netcoredbg#Create(proto) abort
  let self = {
        \ "proto": a:proto,
        \ "name": "netcoredbg",
        \ "GetCmd": function("s:GetCmd"),
        \ "SetConfig": function("s:SetConfig"),
        \ "Dispose": function("s:Dispose")
        \ }

  return self
endfunction

function s:SetConfig(self, prompt, proto) abort
  :call a:prompt.Send(a:prompt, a:proto.Set . " " . "just-my-code 1")
  ":call a:prompt.Send(a:prompt, a:proto.Set . " " . "step-filtering 1")
endfunction

function s:GetCmd(self, cmd_term, args) abort
  let protoname = a:self.proto.name

  let cmd = ["netcoredbg"]
  let cmd += ["--interpreter=" . protoname]
  let cmd += ["--", "dotnet"]

  return cmd
endfunction

function s:Dispose(self) abort
endfunction
