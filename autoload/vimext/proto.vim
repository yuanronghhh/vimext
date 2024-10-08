let s:self = v:null

function vimext#proto#Create(name) abort
  let self = v:null

  if a:name == "mi"
    let self = vimext#miproto#Create()
    let self.name = a:name

  elseif a:name == "mi2"
    let self = vimext#miproto#Create()
    let self.name = a:name

  elseif a:name == "lsp"
    let self = vimext#lspproto#Create()
  else
    :call vimext#logger#Warning("no proto detected for debugger")
    return v:null
  endif

  let s:self = self

  return self
endfunction

function vimext#proto#ParseInputArgs(cmd) abort
  let nameIdx = matchlist(a:cmd, '\(\S*\) \([^\n]*\)')
  if len(nameIdx) <= 2
    return [a:cmd, ""]
  endif

  return [nameIdx[1], nameIdx[2]]
endfunction

function vimext#proto#ProcessMsg(text) abort
  if a:text =~ "(gdb)"
        \ || a:text == ""
    return v:null
  endif

  return a:text
endfunction
