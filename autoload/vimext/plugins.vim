vim9script

var vimext_c_plugins = []

export def LoadPlugin(plugins: list<string>)
  var ppath = ""

  for p in plugins
    if p[1] == ":" || p[0] == "/"
      ppath = p
    else
      ppath = g:vim_plugin .. "/" .. p
    endif

    exec "set rtp+=" .. ppath
  endfor
enddef

def LoadCPlugin(plugins: list<string>)
  var ppath = ""
  for p in plugins
    if p[1] == ":" || p[0] == "/"
      ppath = p
    else
      ppath = g:vim_plugin .. "/" .. p
    endif

    add(vimext_c_plugins, ppath)
  endfor
enddef

def CallCFunc(pindex: number, func_name: string, args: any)
  if !vimext_c_api
    return '<None>'
  endif

  var s = libcall(vimext_c_plugins[pindex], func_name, args)
  if !s
    return '<None>'
  endif

  return s
enddef
