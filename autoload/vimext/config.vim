let g:vimext_loaded = 0

function vimext#config#LoadConfig()
  if g:vimext_loaded == 1
    return
  endif
  call vimext#init()

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
  set encoding=utf-8
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
  set undofile
  set novisualbell
  set t_vb=
  set fdm=syntax
  set t_Co=256
  " switch case 缩进问题
  set cinoptions=l1
  set ssop=blank,buffers,curdir,folds,tabpages

  let $PATH .= ";".$vimext_home."/tools"

  if has("gui_running")
    colorscheme materialtheme
    set columns=120 lines=35
  else
    colorscheme molokai
  endif

  if v:version >= 800
    set ssop+=terminal
    packadd termdebug
  endif

  let $C_HEADERS=vimext#GetSystemHeaderPath()
  set path+=$C_HEADERS
  set grepprg=grep\ -nH
  "中文字体
  if has("unix")
    set clipboard=unnamed
    set guifont=FZFangSong\-Z02S\ bold\ 12
  elseif has("win32")
    set clipboard=unnamed
    set guifont=Fixedsys:h12
    set makeencoding=gbk
    let g:python_cmd = "python"

    let $BashBin = vimext#config#GetWinBash()
    set shell=$BashBin
    let g:tagbar_ctags_bin = vimext#GetBinPath("ctags.exe")
    command! -nargs=0 FullScreen :call vimext#FullScreen()
    command! -nargs=0 GitBash :call vimext#config#GitBash()
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

  " for c develop
  nnoremap <F9>  :HeaderOrCode<cr>
  nnoremap <F10> :cp<cr>
  nnoremap <F11> :cn<cr>

  nnoremap <C-h> <C-w>h
  nnoremap <C-j> gt
  nnoremap <C-k> gT
  nnoremap <C-l> <C-w>l
  nnoremap <C-s> :w<cr>
  nnoremap <F2>  :NERDTreeFind<cr>
  nnoremap <F3>  :tabnew<cr>
  nnoremap <F4>  :close<cr>

  let g:NERDTreeShowHidden = 1
  let g:NERDTreeShowLineNumbers = 0
  let g:NERDTreeAutoDeleteBuffer = 1
  let g:NERDTreeBookmarksFile = g:vim_session."/NERDTreeBookmarks"

  ""let g:hexmode_xxd_options = '-p'
  let g:vimspector_enable_mappings = 'VISUAL_STUDIO'
  let g:pymode_rope_project_root = g:vim_home."/rope"

  let l:plugins = ["tagbar","vim-multiple-cursors","supertab","hexmode","emmet-vim","nerdtree"]
  call vimext#LoadPlugin(l:plugins)

  command! -nargs=? -complete=custom,vimext#session#SessionCompelete OpenSession :call vimext#session#OpenSession("<args>")
  command! -nargs=? -complete=custom,vimext#session#SessionCompelete SaveSession :call vimext#session#SaveSession("<args>")
  command! -nargs=? HeaderOrCode :call vimext#HeaderOrCode()
  command! -nargs=? PythonDoc :call vimext#python#doc("<args>")
  command! -nargs=? JsonFormat :call vimext#JsonFormat()
  command! -nargs=? EditConfig :call vimext#config#Edit()
  command! -nargs=? GenCtags :call vimext#GenCtags()
  command! -nargs=? ManTab :call vimext#ManTab("<args>")
  command! -nargs=+ Debug :call vimext#debug#Debug("<args>")

  autocmd! BufRead *.vs,*.vert,*.glsl,*.frag,*.comp :set ft=c
  autocmd! BufRead *.vue,*.cshtml :set ft=html
  autocmd! BufRead *.vala :set ft=cpp
  autocmd! BufRead *.cst :set ft=javascript
  autocmd! FileType python :nnoremap <buffer> <leader>b :call vimext#python#operate(line('.'))<cr>

  tnoremap <C-j> <C-W>gt
  tnoremap <C-k> <C-W>gT

  let g:vimext_loaded = 1
endfunction

function vimext#config#GetWinBash()
  let l:bpath = vimext#GetBinPath("bash.exe")
  return shellescape(l:bpath)
endfunction

function vimext#config#GitBash()
  let l:cmd = "bash"
  exec ":silent !start ".l:cmd
endfunction

function vimext#config#Edit()
  let l:vimext_config = g:vim_plugin."/vimext/autoload/vimext/config.vim"
  exec ":edit ".l:vimext_config
endfunction
