## Introduce

Vim config easy to copy.

## Recommend, not nessaray

1. git-bash installed for windows.
2. python3 installed.

## How

1. Install vim on `windows/unix` platform.
2. Copy this plugin to "~/.vim/plugins/" if on linux,
   Copy this plugin to "$VIM/plugins/" if on windows.
3. Copy below script content into `vimrc` or `_vimrc` config file for init.

```vimscript
if has("unix")
  let g:vim_home = expand("~/.vim")
else
  let g:vim_home = substitute(expand("$VIM"), '\\', '/', 'g')
endif

let $vimext_home = g:vim_home."/plugins/vimext"
set rtp+=$vimext_home
call vimext#config#LoadConfig()
```

3. add "<git-bash-home>/bin" to path environment if on windows for `grep` linux command.

4. execute `:EditConfig` to edit for your custom.

## Feathers

1. OpenSession && SaveSession for session manage on `<vim_home>/session` directory.
2. colorscheme `materialtheme` for gui, `molokai` for no gui vim.
3. nerdtree, multiple-cursors plugin loaded if exists plugin in `~/plugins` directory.
4. persistent undo in `<vim_home>/undodir`.
5. <F9> `HeaderOrCode` command for c programmer jump `.c` to `.h` if the same directory.

## Python feature
1. comamnd <leader>b will import pdb for python repl debug.
2. PythonDoc <args> for python doc read.
3. JsonFormat use for python json.tools format.

### Window feature
1. terminal find if add `GitPortable/bin/bash.exe` in path.
2. `:Fullscreen` command on win10.
3. add `ctags.exe` to vim path, see `$vimext_home/tools`.
