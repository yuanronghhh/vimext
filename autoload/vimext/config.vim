let g:vimext_loaded = 0

function vimext#config#LoadConfig()
  if g:vimext_loaded == 1
    return
  endif
  :call vimext#Init()

  :set nocompatible
  :behave xterm
  :runtime ftplugin/man.vim

  :syntax on
  :filetype on
  :filetype plugin on
  :filetype indent on

  :set showmatch
  :set fileformats=dos,unix,mac
  :set fileencoding=utf-8
  :set encoding=utf-8
  :set fileencodings=utf-8,gb18030,gb2312,cp936,gbk,ucs-bom,shift-jis
  :set showcmd
  :set number
  :set nowrap
  :set history=100
  :set foldcolumn=1
  :set shiftwidth=2
  :set tabstop=2
  :set softtabstop=2
  :set smarttab
  :set mouse=a
  :set hlsearch
  :set expandtab
  :set incsearch
  :set list
  :set lcs=tab:>-,trail:-,nbsp:~
  :set ruler
  :set cursorline
  :set cursorcolumn
  :set guicursor=a:block-blinkoff0
  :set wildmenu
  :set autoread
  :set autoindent
  :set smartindent
  :set nobackup
  :set backspace=start,indent,eol
  :set whichwrap+=<,>,h,l
  :set colorcolumn=80
  :set scrolloff=3
  :set undofile
  :set novisualbell
  :set t_vb=
  :set foldmethod=syntax
  :set foldlevel=2
  :set t_Co=256
  :colorscheme jellybeans
  " switch case 缩进问题
  :set cinoptions=l1
  :set sessionoptions=blank,buffers,curdir,tabpages,unix

  if has("gui_running")
    :set columns=120 lines=45
    :set guioptions=r
  endif

  if v:version >= 800
    :set sessionoptions+=terminal
    :packadd termdebug
    :packadd cfilter
  endif

  :set grepprg=grep\ -nH

  if has("unix")
    :set clipboard=unnamedplus
    :set guifont=FZFangSong\-Z02S\ bold\ 12
    let $PATH .= ":".$vimext_home."/tools"
  elseif has("win32")
    let $PATH .= ";".$vimext_home."/tools"
    :set clipboard=unnamed
    :set guifont=Consolas:h12

    let g:python_cmd="python"
    let $BashBin=vimext#config#GetWinBash()
    :set errorformat^=%f(%l\\,%c):\ %t%*[^\ ]\ C%n:\ %m,%f(%l\\,%c):\ fatal\ \ %t%*[^\ ]\ C%n:\ %m

    if len($BashBin) > 0
      :set shell=$BashBin
    endif

    let g:tagbar_ctags_bin = vimext#GetBinPath("ctags.exe")
    command! -nargs=0 FullScreen :call vimext#FullScreen()
    command! -nargs=0 GitBash :call vimext#config#GitBash()
  elseif has("mac")
    :set guiligatures
  endif

  if has("nvim")
    let &shellxquote = '('
    let &shellslash = v:true
    let &shellcmdflag = '-c'

    :tnoremap <Esc> <C-\><C-N>
    :tnoremap <expr> <C-R> '<C-\><C-N>"'.nr2char(getchar()).'pi'
    :tnoremap <C-W> <C-\><C-N><C-W>

    :command! Terminal :call vimext#config#TerminalNew()
    :autocmd! TermOpen * :call vimext#config#TerminalEnter()
    :autocmd! TermClose * :call vimext#config#TerminalClose()
    :autocmd! BufEnter term://* :call vimext#config#TerminalEnter()
    :autocmd! BufLeave term://* :call vimext#config#TerminalLeave()
    :tnoremap <C-j> <C-\><C-N>gt
    :tnoremap <C-k> <C-\><C-N>gT
  else
    :tnoremap <C-j> <C-W>gt
    :tnoremap <C-k> <C-W>gT
  endif

  let g:NERDTreeShowHidden = 1
  let g:NERDTreeShowLineNumbers = 0
  let g:NERDTreeAutoDeleteBuffer = 1
  let g:NERDTreeBookmarksFile = g:vim_session."/NERDTreeBookmarks"

  let g:hexmode_xxd_options = '-p'

  :call vimext#config#ALEConfig()

  let plugins = [
        \ "vim-multiple-cursors",
        \ "emmet-vim",
        \ "supertab",
        \ "tagbar",
        \ "hexmode",
        \ "ale",
        \ "nerdtree"
        \ ]
  :call vimext#plugins#LoadPlugin(plugins)
  :call vimext#debug#Init()

  :command! -nargs=? -complete=custom,vimext#session#SessionCompelete OpenSession :call vimext#session#OpenSession("<args>")
  :command! -nargs=? -complete=custom,vimext#session#SessionCompelete SaveSession :call vimext#session#SaveSession("<args>")
  :command! -nargs=? HeaderOrCode :call vimext#HeaderOrCode()
  :command! -nargs=? EditConfig :call vimext#config#Edit()
  :command! -nargs=? ManTab :call vimext#ManTab("<args>")

  :autocmd! QuickfixCmdPost make :call vimext#config#QuickFixFunc()
  :autocmd! BufRead *.vs,*.vert,*.glsl,*.frag,*.comp :set syntax=c
  :autocmd! BufRead *.vue,*.cshtml :set syntax=html
  :autocmd! BufRead *.vala,*.mojom :set syntax=cs
  :autocmd! BufRead *.cst :set syntax=javascript
  :autocmd! BufRead * :call vimext#LargeFile()
  :autocmd! BufEnter *.c,*.h,*.cs ++once :call vimext#SetEditor()

  :inoremap < <><ESC>i
  :inoremap > <c-r>=vimext#ClosePair('>')<CR>
  :inoremap ( ()<ESC>i
  :inoremap ) <c-r>=vimext#ClosePair(')')<CR>
  :inoremap } <c-r>=vimext#ClosePair('}')<CR>
  :inoremap [ []<ESC>i
  :inoremap ] <c-r>=vimext#ClosePair(']')<CR>
  :inoremap " ""<ESC>i
  :inoremap ' ''<ESC>i
  :inoremap <c-o> <ESC>o
  :inoremap { {}<ESC>i
  :nnoremap x "_x
  :nnoremap X "_X
  :vnoremap x "_x
  :vnoremap X "_X

  " for c develop
  :nnoremap <leader>c :GetComment<cr>
  :nnoremap <F9> :HeaderOrCode<cr>

  :nnoremap <F10> :cprevious<cr>
  :nnoremap <F11> :cnext<cr>

  :nnoremap <C-j> gt
  :nnoremap <C-k> gT
  :nnoremap <C-h> <C-w>h
  :nnoremap <C-l> <C-w>l
  :nnoremap <C-s> :w<cr>
  :nnoremap <F2>  :NERDTreeFind<cr>
  :nnoremap <F3>  :tabnew<cr>
  :nnoremap <F4>  :close<cr>

  let g:vimext_loaded = 1
endfunction

function vimext#config#GetWinBash()
  let bpath = vimext#GetBinPath("bash.exe")
  if len(bpath) == 0
    return ""
  endif

  return shellescape(bpath)
endfunction

function vimext#config#nvimConfig()
endfunction

function vimext#config#ALEConfig()
  let g:ale_set_loclist = 0
  let g:ale_set_balloons = 0
  let g:ale_linters_explicit = 1
  let g:ale_lint_on_save = 0
  let g:ale_lint_delay = 1000
  let g:ale_c_clangd_options = '--pch-storage=memory'
  let g:ale_linters = { 'cs': ['mcs'], 'c': ['clangd'], 'python': ['pylint'] }
  let g:ale_python_pylint_options = "--errors-only"

  if has("win32")
    let g:ale_c_parse_compile_commands = 0
    let g:ale_c_build_dir_names = []
  endif

  :nnoremap <C-M>[ :ALEFindReferences -quickfix<cr>
  :nnoremap <C-M>] :ALEGoToDefinition -split<cr>
  :nnoremap <C-M>h :ALEHover<cr>
endfunction

function vimext#config#GitBash()
  let cmd = "bash"
  :exec ":silent !start ".cmd
endfunction

function vimext#config#Edit()
  let vimext_config = g:vim_plugin."/vimext/autoload/vimext/config.vim"
  :exec ":edit ".vimext_config
endfunction

function vimext#config#TerminalNew()
  :split term://bash
endfunction

function vimext#config#TerminalEnter()
  if &buftype == 'terminal'
    :startinsert
  endif
endfunction

function vimext#config#TerminalClose()
  :execute 'bdelete!'
endfunction

function vimext#config#TerminalLeave()
  :stopinsert
endfunction

function vimext#config#QuickFixFunc()
  if &ft == "cs"
    let all = getqflist()
    let oerror = filter(all, "v:val.type == \"e\"")

    :call setqflist(oerror, "r")
  endif
  :redraw
endfunction
