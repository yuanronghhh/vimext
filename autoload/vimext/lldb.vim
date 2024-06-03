function vimext#lldb#Create(proto) abort
  let self = {
        \ "proto": a:proto,
        \ "name": "lldb",
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
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, "breakpoint pending on"))
    :call a:prompt.Send(a:prompt, a:proto.Call(a:proto, "process launch --stop-at-entry"))
  else
    :call a:prompt.Send(a:prompt, a:proto.Set(a:proto, "breakpoint pending on"))
  endif
endfunction

function s:GetCmd(self, oterm, args) abort
  let tty = a:oterm.tty
  let protoname = a:self.proto.name

  return s:GetLLDBCmd(protoname, tty, a:args)
endfunction

function s:GetLLDBCmd(protostr, tty, args) abort
  let protoname = a:protostr
  let cmd = ["lldb-mi"]
  let cmd += ["--interpreter=" . protoname]

  if len(a:args) == 1
    let a:args[0] = vimext#debug#DecodeFilePath(a:args[0])
  endif
  let cmd += a:args

  return cmd
endfunction

function s:Dispose(self) abort
endfunction
