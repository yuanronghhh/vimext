let s:self = v:null

function vimext#dbg#Create(name, proto) abort
  let self = v:null

  if a:name == "csharp"
    let self = vimext#netcoredbg#Create(a:proto)
  elseif a:name == "c"
    let self = vimext#gccdbg#Create(a:proto)
  else
    return v:null
  endif
  let s:self = self

  return self
endfunction

function s:Dispose(self) abort
endfunction
