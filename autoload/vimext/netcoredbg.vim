function vimext#netcoredbg#Create(proto) abort
  let self = {
        \ "proto": a:proto,
        \ "name": "netcoredbg",
        \ "mode": 1,
        \ "GetCmd": function("s:GetCmd"),
        \ "SetConfig": function("s:SetConfig"),
        \ "Dispose": function("s:Dispose")
        \ }

  return self
endfunction

function s:SetConfig(self, prompt, proto) abort
  if a:proto.name == "lsp"
  else
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, " " . "just-my-code 1"))
  endif
endfunction

function s:GetCmd(self, cmd_term, args) abort
  let protoname = a:self.proto.name
  if a:self.proto.name == "lsp"
    let protoname = "vscode"
    let a:self.mode = 3
  endif

  let cmd = ["netcoredbg"]
  let cmd += ["--interpreter=" . protoname]
  let cmd += a:args

  return cmd
endfunction

function s:Dispose(self) abort
endfunction
