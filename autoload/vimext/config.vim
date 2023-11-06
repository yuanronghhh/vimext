let g:vimext_loaded = 0

function vimext#config#LoadConfig()
  if g:vimext_loaded == 1
    return
  endif
  call vimext#init()

  set nocompatible
  behave xterm
  runtime ftplugin/man.vim

  syntax on
  filetype on
  filetype plugin on
  filetype indent on

  set showmatch
  set guioptions=r
  set fileformats=dos,unix,mac
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

  if has("gui_running")
    colorscheme materialtheme
    set columns=120 lines=45
  else
    colorscheme molokai
  endif

  if v:version >= 800
    set ssop+=terminal
    packadd termdebug
  endif

  set grepprg=grep\ -nH

  if has("unix")
    set clipboard=unnamedplus
    set guifont=FZFangSong\-Z02S\ bold\ 12
    let $PATH .= ":".$vimext_home."/tools"
  elseif has("win32")
    let $PATH .= ";".$vimext_home."/tools"
    set clipboard=unnamed
    set guifont=Fixedsys
    set makeencoding=gbk
    let g:python_cmd="python"
    let $BashBin=vimext#config#GetWinBash()
    set errorformat^=
          \%f(%l\\,%c):\ %t%*[^\ ]\ C%n:\ %m,
          \%f(%l\\,%c):\ fatal\ \ %t%*[^\ ]\ C%n:\ %m

    if len($BashBin) > 0
      set shell=$BashBin
    endif

    let g:tagbar_ctags_bin = vimext#GetBinPath("ctags.exe")
    command! -nargs=0 FullScreen :call vimext#FullScreen()
    command! -nargs=0 GitBash :call vimext#config#GitBash()
  elseif has("mac")
    set guiligatures
    set noanti
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
  nnoremap <leader>c :GetComment<cr>
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

  "let g:hexmode_xxd_options = '-p'
  let g:ale_lint_on_text_changed = 'never'
  let g:ale_c_parse_compile_commands = 1
  let g:ale_linters_explicit = 1
  let g:ale_linters =
        \ {
        \ 'c': ['clangtidy', 'gcc', 'clangd'],
        \ 'python': ['pylint']
        \ }

  let l:plugins = ["vim-multiple-cursors", "supertab", "nerdtree", "ale"]
  call vimext#plugins#LoadPlugin(l:plugins)

  command! -nargs=? -complete=custom,vimext#session#SessionCompelete OpenSession :call vimext#session#OpenSession("<args>")
  command! -nargs=? -complete=custom,vimext#session#SessionCompelete SaveSession :call vimext#session#SaveSession("<args>")
  command! -nargs=? HeaderOrCode :call vimext#HeaderOrCode()
  command! -nargs=? EditConfig :call vimext#config#Edit()
  command! -nargs=? TabMan :call vimext#TabMan("<args>")

  autocmd! BufRead *.vs,*.vert,*.glsl,*.frag,*.comp :set ft=c
  autocmd! BufRead *.vue,*.cshtml :set ft=html
  autocmd! BufRead *.vala :set ft=cpp
  autocmd! BufRead *.cst :set ft=javascript

  tnoremap <C-j> <C-W>gt
  tnoremap <C-k> <C-W>gT

  let g:vimext_loaded = 1
endfunction

function vimext#config#GetWinBash()
  let l:bpath = vimext#GetBinPath("bash.exe")
  if len(l:bpath) == 0
    return ""
  endif

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
