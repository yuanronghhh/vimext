vim9script

import "../vimext.vim" as VimExt
import "./plugins.vim" as Plugin
import "./debug.vim" as Debug
import "./session.vim" as Session
import "./logger.vim" as Logger

var vimext_loaded = 0

export def LoadConfig()
  if vimext_loaded == 1
    return
  endif
  call VimExt.Init()

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
  # switch case 缩进问题
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

  $PATH = $PATH .. ";" .. $vimext_home .. "/tools"

  if has("unix")
    set clipboard=unnamedplus
    set guifont=FZFangSong\-Z02S\ bold\ 12
  elseif has("win32")
    set clipboard=unnamed
    set guifont=Fixedsys
    set makeencoding=gbk
    var python_cmd = "python"
    $BashBin = GetWinBash()
    set errorformat^=
          \%f(%l\\,%c):\ %t%*[^\ ]\ C%n:\ %m,
          \%f(%l\\,%c):\ fatal\ \ %t%*[^\ ]\ C%n:\ %m

    if len($BashBin) > 0
      set shell=$BashBin
    endif

    var tagbar_ctags_bin = VimExt.GetBinPath("ctags.exe")
    command! -nargs=0 FullScreen :call VimExt.FullScreen()
    command! -nargs=0 GitBash :call GitBash()
  elseif has("mac")
    set guiligatures
    set noanti
  endif

  inoremap < <><ESC>i
  inoremap > <c-r>=VimExt.VClosePair('>')<CR>
  inoremap ( ()<ESC>i
  inoremap ) <c-r>=VimExt.VClosePair(')')<CR>
  inoremap } <c-r>=VimExt.VClosePair('}')<CR>
  inoremap [ []<ESC>i
  inoremap ] <c-r>=VimExt.VClosePair(']')<CR>
  inoremap " ""<ESC>i
  inoremap ' ''<ESC>i
  inoremap <c-o> <ESC>o
  inoremap { {}<ESC>i
  nnoremap x "_x
  nnoremap X "_X
  vnoremap x "_x
  vnoremap X "_X

  # for c develop
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

  g:NERDTreeShowHidden = 1
  g:NERDTreeShowLineNumbers = 0
  g:NERDTreeAutoDeleteBuffer = 1
  g:NERDTreeBookmarksFile = g:vim_session .. "/NERDTreeBookmarks"

  g:hexmode_xxd_options = '-p'
  g:ale_lint_on_text_changed = 'never'
  g:ale_set_loclist = 1
  g:ale_c_parse_compile_commands = 1
  g:ale_c_build_dir = 'build'
  g:ale_linters_explicit = 1
  g:ale_linters = {
    'cs': ['mcs'],
    'c': ['clangtidy', 'gcc', 'clangd'],
    'python': ['pylint']
  }

  var plugins = ["vim-multiple-cursors", "supertab", "nerdtree", "TagBar"]
  call Plugin.LoadPlugin(plugins)

  call Debug.Init()

  command! -nargs=? -complete=custom,Session.SessionCompelete OpenSession :call Session.OpenSession("<args>")
  command! -nargs=? -complete=custom,Session.SessionCompelete SaveSession :call Session.SaveSession("<args>")
  command! -nargs=? HeaderOrCode :call VimExt.VHeaderOrCode()
  command! -nargs=? EditConfig :call Edit()
  command! -nargs=? TabMan :call VimExt.VTabMan("<args>")

  autocmd! BufRead *.vs,*.vert,*.glsl,*.frag,*.comp :set ft=c
  autocmd! BufRead *.vue,*.cshtml :set ft=html
  autocmd! BufRead *.vala :set ft=cpp
  autocmd! BufRead *.cst :set ft=javascript
  autocmd! BufRead *.cs :set shiftwidth=4

  tnoremap <C-j> <C-W>gt
  tnoremap <C-k> <C-W>gT

  vimext_loaded = 1
enddef

def GetWinBash(): string
  var bpath = VimExt.GetBinPath("bash.exe")
  if len(bpath) == 0
    return ""
  endif

  return shellescape(bpath)
enddef

def GitBash()
  var cmd = "bash"
  exec ":silent !start " .. cmd
enddef

def Edit()
  var vimext_config = g:vim_plugin."/vimext/autoload/vimext/config.vim"
  exec ":edit " .. vimext_config
enddef
