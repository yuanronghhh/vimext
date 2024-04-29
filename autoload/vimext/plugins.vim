let g:vimext_c_plugins = []

function vimext#plugins#LoadPlugin(plugins) abort
  let ppath = ""

  for p in a:plugins
    if p[1] == ":" || p[0] == "/"
      let ppath = p
    else
      let ppath = g:vim_plugin."/".p
    endif

    :execute "set rtp+=".ppath
  endfor
endfunction

function vimext#plugins#LoadCPlugin(plugins) abort
  let ppath = ""
  for p in a:plugins
    if p[1] == ":" || p[0] == "/"
      let ppath = p
    else
      let ppath = g:vim_plugin."/".p
    endif

    add(g:vimext_c_plugins, ppath)
  endfor
endfunction

function vimext#plugins#CallCFunc(pindex, func_name, args) abort
  if !g:vimext_c_api
    return '<None>'
  endif

  let s = libcall(g:vimext_c_plugins[pindex], func_name, args)
  if !s
    return '<None>'
  endif

  return s
endfunction
