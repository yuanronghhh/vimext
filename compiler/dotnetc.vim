if exists("current_compiler")
  finish
endif
let current_compiler = "dotnetc"

if exists(":CompilerSet") != 2 " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

CompilerSet errorformat=%E%f(%l\\,%c):\ %trror\ %m,
      \%f\ :\ %trror\ NU%n:\ %m,
      \%W%f(%l\\,%c):\ %tarning\ %m,
      \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save
