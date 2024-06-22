if exists("current_compiler")
  finish
endif
let current_compiler = "clang"

let s:cpo_save = &cpo
set cpo&vim

CompilerSet errorformat=
      \%f(%l\\,%c):\ %t%*[^\ ]\:\ %m,
      \%f(%l\\,%c):\ %t%*[^\ ]\ :\ %m,
      \%f(%l\\,%c):\ fatal\ %t%*[^\ ]\ :\ %m

if exists('g:compiler_clang_ignore_unmatched_lines')
  CompilerSet errorformat+=%-G%.%#
endif

let &cpo = s:cpo_save
unlet s:cpo_save

