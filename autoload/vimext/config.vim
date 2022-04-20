let g:vimext_loaded = 0

function vimext#config#LoadConfig()
  if g:vimext_loaded == 1
    return
  endif

  behave xterm
  runtime ftplugin/man.vim

  set nocompatible

  syntax on
  filetype on
  filetype plugin on
  filetype indent on
  set showmatch
  set guioptions=r
  set fileformats=unix,dos,mac
  set fileencoding=utf-8
  set fileencodings=utf-8,gb18030,gb2312,cp936,gbk,ucs-bom,shift-jis
  set showcmd
  set number
  set nowrap
  set history=100
  set foldcolumn=1
  set shiftwidth=2
  set tabstop=2
  set softtabstop=2
  set smarttab
  set mouse=a
  set hlsearch
  set expandtab
  set incsearch
  set list
  set lcs=tab:>-,trail:-,nbsp:~
  set ruler
  set cursorline
  set cursorcolumn
  set guicursor=a:block-blinkoff0
  set wildmenu
  set autoread
  set autoindent
  set smartindent
  set nobackup
  set backspace=start,indent,eol
  set whichwrap+=<,>,h,l
  set colorcolumn=80
  set scrolloff=3

  set novisualbell
  set t_vb=
  set fdm=syntax
  set t_Co=256
  " switch case 缩进问题
  set cinoptions=l1
  if has("gui_running")
    set columns=120 lines=40
  endif
  set undofile
  set ssop=blank,buffers,curdir,folds,tabpages,terminal
  let g:python_cmd = "python3"

  let &undodir = g:vim_home."/undodir"
  let g:vim_plugin = g:vim_home."/plugins"
  let g:vim_session = g:vim_home."/session"
  let g:vim_ropepath = g:vim_home."/rope"


  if has("unix")
    set linespace=-3
    set clipboard=unnamed
    set path+=/usr/include/x86_64-linux-gnu,/usr/include,/usr/local/include,/usr/lib/gcc/x86_64-linux-gnu/9/include,/usr/include/c++/9,/usr/include/x86_64-linux-gnu/c++/9,/usr/include/c++/9/backward,/home/greyhound/Local/include
    set guifont=Ubuntu\ Mono\ 12
  else
    set clipboard=unnamed
    set guifont=Fixedsys\ Excelsior\ 3.01\ h12
    set grepprg=grep\ -nH
    let g:python_cmd = "python"

    let $BashEnv = vimext#config#GetShell()
    set shell=$BashEnv
  endif

  inoremap < <><ESC>i
  inoremap > <c-r>=vimext#ClosePair('>')<CR>
  inoremap ( ()<ESC>i
  inoremap ) <c-r>=vimext#ClosePair(')')<CR>
  inoremap } <c-r>=vimext#ClosePair('}')<CR>
  inoremap [ []<ESC>i
  inoremap ] <c-r>=vimext#ClosePair(']')<CR>
  inoremap " ""<ESC>i
  inoremap ' ''<ESC>i
  inoremap <c-o> <ESC>o
  inoremap { {}<ESC>i

  nnoremap x "_x
  nnoremap X "_X

  vnoremap x "_x
  vnoremap X "_X

  nnoremap <C-h> <C-w>h
  nnoremap <C-j> gt
  nnoremap <C-k> gT
  nnoremap <C-l> <C-w>l
  nnoremap <C-s> :w<cr>
  nnoremap <F2> :HeaderOrCode<cr>
  nnoremap <F3> :tabnew<cr>
  nnoremap <F4> :close<cr>
  nnoremap <F7> :tab Man -s2,3 <cword><cr>

  let g:ycm_goto_buffer_command = 'split'
  let g:ycm_filepath_completion_use_working_dir = 0

  let g:vimspector_enable_mappings = 'HUMAN'

  let g:NERDTreeShowHidden = 1
  let g:NERDTreeShowLineNumbers = 0
  let g:NERDTreeAutoDeleteBuffer = 1
  let g:NERDTreeBookmarksFile = g:vim_session."/NERDTreeBookmarks"

  let g:hexmode_xxd_options = '-p'
  let g:vimspector_enable_mappings = 'HUMAN'

  let $vundle_home = g:vim_plugin."/Vundle.vim"
  set rtp+=$vundle_home

  packadd termdebug
  call vundle#begin(g:vim_plugin)
  "Plugin 'https://github.com/puremourning/vimspector'
  "Plugin 'https://github.com/w0rp/ale'
  "Plugin 'https://github.com/lilydjwg/colorizer.git'
  "Plugin 'https://github.com/Valloric/YouCompleteMe.git'

  Plugin 'https://github.com/fidian/hexmode.git'
  Plugin 'https://github.com/mattn/emmet-vim.git'
  Plugin 'https://github.com/majutsushi/tagbar.git'
  Plugin 'https://github.com/terryma/vim-multiple-cursors.git'
  Plugin 'https://github.com/preservim/nerdtree.git'
  Plugin 'https://github.com/ervandew/supertab.git'
  call vundle#end()

  if has("gui_running")
    colorscheme materialtheme
  else
    colorscheme molokai
  endif

  command! -nargs=? -complete=custom,vimext#SessionCompelete OpenSession :call vimext#OpenSession("<args>")
  command! -nargs=? -complete=custom,vimext#SessionCompelete SaveSession :call vimext#SaveSession("<args>")
  command! -nargs=? HeaderOrCode :call vimext#HeaderOrCode()
  command! -nargs=? PythonDoc :call vimext#pypdb#doc("<args>")
  command! -nargs=? JsonFormat :call vimext#JsonFormat()
  command! -nargs=? EditConfig :call vimext#config#Edit()
  command! -nargs=? GenCtags :call vimext#GenCtags()
  command! -nargs=? GetBinPath :call vimext#GetBinPath("<args>")

  autocmd! BufRead *.vs,*.vert,*.glsl,*.frag :set ft=c
  autocmd! BufRead *.vue :set ft=html
  autocmd! BufRead *.vala :set ft=cpp
  autocmd! BufRead *.cst :set ft=javascript
  autocmd! FileType python :nnoremap <buffer> <leader>b :call vimext#pypdb#operate(line('.'))<cr>
  autocmd! TerminalOpen * if &buftype == 'terminal' | wincmd J | endif

  let g:vimext_loaded = 1
endfunction

function vimext#config#GetShell()
  let l:bpath = vimext#GetBinPath("bash")
  return "\"".l:bpath."\""
endfunction

function vimext#config#Edit()
  let l:vimext_config = g:vim_plugin."/vimext/autoload/vimext/config.vim"
  exec ":edit ".l:vimext_config
endfunction
