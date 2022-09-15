function! vimext#channel#init()
endfunction

function! MyHandler(channel, msg)
  echo "from the handler: " . a:msg
endfunction
