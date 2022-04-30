function! vimext#channel#init()
  let channel = ch_open("localhost:8765")

  call ch_sendexpr(channel, 'hello!', {'callback': 'MyHandler'})
endfunction

function! MyHandler(channel, msg)
  echo "from the handler: " . a:msg
endfunction

call vimext#channel#init()
