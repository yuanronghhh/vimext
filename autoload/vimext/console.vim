let s:self = v:null

function vimext#console#Create(dbg, funcs) abort
  let console = v:null
  if has("win32") || a:dbg.name == "netcoredbg"
    let console = vimext#prompt#Create(a:funcs)
  else
    let console = vimext#term#Create(a:funcs)
  endif

  if console is v:null
    return v:null
  endif

  if !has('terminal')
    :call vimext#logger#Error("+terminal not enabled in vim")
    return v:null
  endif
  let s:self = console

  return console
endfunction


function s:Dispose(self) abort
endfunction
