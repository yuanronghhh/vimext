if exists( "g:loaded_vimext" )
  finish
endif

let g:loaded_vimext = 1
call vimext#SetUp()
