function vimext#debug#Debug(param) abort
  exec ":tabnew"
  exec ":Termdebug ".a:param
endfunction
