## Introduce

Vim config for portable.
this plugin is my vim config. zero dependencies.

## Required for feature

1. git-bash installed for windows.
2. python3 installed.

## How to install

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
4. execute `:EditConfig` to edit for your config.

## Feathers

1. command OpenSession && SaveSession for session manage on `<vim_home>/session` directory.
2. colorscheme `materialtheme` for gui, `molokai` for no gui vim.
3. nerdtree, multiple-cursors plugin loaded if exists plugin in `~/plugins` directory.
4. persistent undo in `<vim_home>/undodir`.
5. command `HeaderOrCode` command for c programmer jump `.c` to `.h` if the same directory.

## Python feature
1. comamnd `<leader>b` will import pdb for python repl debug.
2. command `PythonDoc` for python doc read.
3. command `JsonFormat` use for python json.tools format.
4. command `GetComment` generate comment for function only python, c, C#.
5. command `GenCtags` to generate tags and automatically update tags when saved one file.
6. command `ManTab` for new tab for man page.
7. command `DbgDebug` for reimplement `Termdebug`.

### Window feature
1. terminal find if add `GitPortable/bin/bash.exe` in path.
2. command `:Fullscreen` command for win10.
3. add `ctags.exe` to vim path, see `$vimext_home/tools`.

### Debugger
1. install `clang/gdb`, `netcoredbg`
2. for `c` language, set arguments `-gdwarf` on windows,
   for `c#` language, set `<EmbedAllSources>true</EmbedAllSources>` to `.csproj` file in `<PropertyGroup></PropertyGroup>`
3. send debug command to vim
```bash
   $ gvim --servername ${VIM_SESSION} --remote-send ':DbgDebug ${DEBUGGER} ${ARGS}<cr>'
```
   this will open newtab for debug
4. press `q` for close debug tab
