let g:vimext_c_plugins = []

function vimext#plugins#LoadPlugin(plugins)
  let l:ppath = ""

  for l:p in a:plugins
    if l:p[1] == ":" || l:p[0] == "/"
      let l:ppath = l:p
    else
      let l:ppath = g:vim_plugin."/".l:p
    endif

    exec "set rtp+=".l:ppath
  endfor
endfunction

function vimext#plugins#LoadCPlugin(plugins)
  let l:ppath = ""
  for l:p in a:plugins
    if l:p[1] == ":" || l:p[0] == "/"
      let l:ppath = l:p
    else
      let l:ppath = g:vim_plugin."/".l:p
    endif

    add(g:vimext_c_plugins, l:ppath)
  endfor
endfunction

function vimext#plugins#CallCFunc(pindex, func_name, args)
  if !g:vimext_c_api
    return '<None>'
  endif

  let l:s = libcall(g:vimext_c_plugins[pindex], func_name, args)
  if !l:s
    return '<None>'
  endif

  return l:s
endfunction
