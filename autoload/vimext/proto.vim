let s:self = v:null

function vimext#proto#Create(name) abort
  let self = v:null
  if a:name == "mi"
    let self = vimext#miproto#MiCreate()
    let self.name = a:name

  elseif a:name == "mi2"
    let self = vimext#miproto#MiCreate()
    let self.name = a:name

  elseif a:name == "dap"
    let self = vimext#dapproto#DapCreate()
  else
    let self = vimext#miproto#MiCreate()
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
        \ || a:text[0] == "&"
    return v:null
  endif

  return a:text
endfunction
