## Introduce

Vim config for portable.
no plugin is neccessary.

## Recommend

1. git-bash installed for windows.
2. python3 installed.

## How

1. Copy this plugin to "~/.vim/plugins/" on linux,
   Copy to "$VIM/plugins/" on windows.

2. Copy below script to `vimrc` or `_vimrc` config for init.

```vimscript
if has("unix")
  let g:vim_home = expand("~/.vim")
else
  let g:vim_home = substitute(expand("$VIM"), '\\', '/', 'g')
endif

let $vimext_home = g:vim_home."/plugins/vimext"
set rtp+=$vimext_home
call vimext#setUp()
```

3. add "<git-bash-home>/bin" to path environment if on windows for `grep` linux command.

4. execute `:EditConfig` to edit for your custom.

## Feathers

1. OpenSession && SaveSession for session manage on `<vim_home>/session` directory.
2. colorscheme `materialtheme` for gui, `molokai` for no gui vim.
3. nerdtree, multiple-cursors, emmet-vim plugin loaded if copied plugin to `~/plugins` directory.
4. persistent undo in `<vim_home>/undodir`.
5. <F2> `HeaderOrCode` command for c programmer jump `.c` to `.h` with same directory.

## Python feature
1. comamnd <leader>b will import pdb for python repl debug.
2. PythonDoc <args> for python doc read.
3. JsonFormat use for python json.tools format.

### WIndow feature
1. terminal find if add "bash.exe" in path.
2. <F6> for fullscreen on win10.
3. add ctags.exe and make.exe to vim path, see `$vimext_home/tools`.
