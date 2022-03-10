#my Custom vim config

this is plugin for portable copy config.

## How
1. Download Vundle to `<vim_home>/plugins` directory,
`vim_home` path is `~/.vim` on unix.
`vim_home` path is `$VIM` on windows.

Vundle github home url is:
git clone 'https://github.com/VundleVim/Vundle.vim.git' ~/.vim/plugins

2. Copy below script to `vimrc / _vimrc` config file.
```vimscript
if has("unix")
  let g:vim_home = expand("~/.vim")
else
  let g:vim_home = substitute(expand("$VIM"), '\\', '/', 'g')
endif

let g:vim_plugin = g:vim_home."/plugins"
let $vimext_home = g:vim_plugin."/vimext"
set rtp+=$vimext_home
call vimext#SetUp()
```

3. execute `:EditConfig` to edit.

## feathers

1. OpenSession && SaveSession for session manage on `<vim_home>/session` directory.
2. colorscheme `materialtheme` for gui, `molokai` for no gui vim.
3. nerdtree, multiple-cursors, emmet-vim plugin loaded
4. persistent undo in `<vim_home>/undodir` if you create that directory.
