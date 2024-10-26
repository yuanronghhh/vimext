set background=dark

hi clear

if version > 580
  " no guarantees for version 5.8 and below, but this makes it stop
  " complaining
  :highlight clear
  if exists("syntax_on")
    syntax reset
  endif
endif

let g:colors_name="materialtheme"
if (has('termguicolors') && &termguicolors) || has('gui_running')
  let g:terminal_ansi_colors = ['#1c1c1c', '#d75f5f', '#87af87', '#afaf87', '#5f87af', '#af87af', '#5f8787', '#9e9e9e', '#767676', '#d7875f', '#afd7af', '#d7d787', '#87afd7', '#d7afd7', '#87afaf', '#bcbcbc']
endif

:highlight Boolean         guifg=#AE81FF
:highlight Number gui=bold guifg=#fdffdd
:highlight Character       guifg=#E6DB74
:highlight String          guifg=#80cbc4
:highlight Conditional     guifg=#F92672               gui=bold
:highlight Constant term=underline ctermfg=13 gui=bold guifg=#ffffff guibg=#434343
:highlight Cursor guifg=#037655 guibg=#ffffff
:highlight iCursor         guifg=#000000 guibg=#F8F8F0
:highlight Debug           guifg=#BCA3A3               gui=bold
:highlight Define          guifg=#66D9EF
:highlight Delimiter guifg=#8787df
:highlight DiffAdd term=bold ctermbg=1 guibg=#13354A
:highlight DiffChange term=bold ctermbg=5 guifg=#89807D guibg=#4C4745
:highlight DiffDelete term=bold ctermfg=9 ctermbg=3 gui=bold guifg=#960050 guibg=#1E0010
:highlight DiffText term=reverse cterm=bold ctermbg=12 gui=bold guibg=#4C4745

:highlight Directory term=bold ctermfg=11 gui=bold guifg=#8a8a8a
:highlight Error term=reverse ctermfg=15 ctermbg=12 guifg=#E6DB74 guibg=#1E0010
:highlight ErrorMsg term=standout ctermfg=15 ctermbg=4 gui=bold guifg=#F92672 guibg=#232526
:highlight Exception       guifg=#A6E22E               gui=bold
:highlight Float           guifg=#AE81FF
:highlight FoldColumn term=standout ctermfg=11 ctermbg=8 gui=bold guifg=#afafdf guibg=#263238
:highlight Folded term=standout ctermfg=11 ctermbg=8 guifg=#80cbc4 guibg=#37474f
:highlight Function guifg=#dfafdf
:highlight Identifier term=underline cterm=bold ctermfg=11 guifg=#AD7FA8
:highlight Ignore          guifg=#808080 guibg=bg
:highlight IncSearch term=reverse cterm=reverse gui=reverse guifg=#C4BE89 guibg=#000000

:highlight Keyword         guifg=#F92672               gui=bold
:highlight Label           guifg=#E6DB74               gui=none
:highlight Macro           guifg=#C4BE89               gui=none
:highlight SpecialKey term=bold ctermfg=9 guifg=#ffffff guibg=#263238

:highlight MatchParen term=reverse ctermbg=3 gui=bold guifg=#ffb74d guibg=#37473f
:highlight ModeMsg term=bold cterm=bold gui=bold guifg=#E6DB74
:highlight MoreMsg term=bold ctermfg=10 gui=bold guifg=#E6DB74
:highlight Operator        guifg=#F92672

:" complete menu
:highlight Pmenu ctermfg=0 ctermbg=13 guifg=#80cbc4 guibg=#37474f
:highlight PmenuSel ctermfg=8 ctermbg=0 guifg=#afddff guibg=#363838
:highlight PmenuSbar ctermbg=7 guibg=#080808
:highlight PmenuThumb ctermbg=15 guifg=#66D9EF guibg=White

:highlight PreCondit       guifg=#A6E22E               gui=bold
:highlight PreProc term=underline ctermfg=9 guifg=#e9ba6e
:highlight Question term=standout ctermfg=10 gui=bold guifg=#66D9EF
:highlight Repeat          guifg=#F92672               gui=bold
:highlight Search term=reverse cterm=underline ctermfg=0 ctermbg=14 gui=underline guifg=#fdffdd guibg=#463238
:" marks
:highlight SignColumn term=standout ctermfg=11 ctermbg=8 guifg=#A6E22E guibg=#263238
:highlight SpecialChar     guifg=#F92672               gui=bold
:highlight SpecialComment  guifg=#7E8E91               gui=bold
:highlight Special term=underline ctermfg=12 guifg=#64b5f6 guibg=bg
if has("spell")
  :highlight SpellBad term=reverse ctermbg=12 gui=undercurl guifg=#e57373 guisp=#e57373
  :highlight SpellCap term=reverse ctermbg=9 gui=undercurl guisp=#7070F0
  :highlight SpellLocal term=underline ctermbg=11 gui=undercurl guisp=#70F0F0
  :highlight SpellRare term=reverse ctermbg=13 gui=undercurl guisp=#FFFFFF
endif
:highlight Statement term=bold ctermfg=14 gui=bold guifg=#ffdf87
:highlight StatusLine term=bold,reverse cterm=bold,reverse gui=bold,reverse guifg=#000000 guibg=#ffffff
:highlight StatusLineNC term=reverse cterm=reverse gui=reverse guifg=#222222 guibg=#ffffff
:highlight StorageClass    guifg=#FD971F               gui=none
:highlight Structure       guifg=#66D9EF
:highlight Tag             guifg=#F92672               gui=none
:highlight Title term=bold ctermfg=13 gui=bold guifg=#ffb74d
:highlight Todo term=standout ctermfg=0 ctermbg=14 gui=bold guifg=#80cbc4 guibg=#37474f

:highlight Typedef         guifg=#66D9EF
:highlight Type term=underline ctermfg=10 guifg=#aed2d3
:highlight Underlined      guifg=#808080               gui=underline

:highlight VertSplit term=reverse cterm=reverse gui=bold guifg=#252525 guibg=#252525
:highlight VisualNOS term=bold,underline cterm=bold,underline gui=bold,underline guibg=#403D3D
:highlight Visual term=reverse cterm=reverse ctermfg=208 guifg=#ffffff guibg=#037655
:highlight WarningMsg term=standout ctermfg=12 gui=bold guifg=#FFFFFF guibg=#333333
:highlight WildMenu term=standout ctermfg=0 ctermbg=14 guifg=#66D9EF guibg=#000000

:highlight TabLineFill term=reverse cterm=reverse gui=reverse guifg=#1B1D1E guibg=#263238
:highlight TabLine term=underline cterm=underline ctermfg=15 ctermbg=8 guifg=#808080 guibg=#1B1D1E

:highlight Normal guifg=#dcdcdc guibg=#252525
:highlight Comment term=bold ctermfg=7 guifg=#afafaf
:highlight CursorLine term=underline cterm=underline guibg=#373737
:highlight CursorLineNr term=bold ctermfg=14 guifg=#FD971F
:highlight CursorColumn term=reverse ctermbg=8 guibg=#373737
:highlight ColorColumn term=reverse ctermbg=4 guifg=#ffffff guibg=#1c1c1c
:highlight LineNr term=underline ctermfg=14 guifg=#939393 guibg=#000000
:highlight NonText term=bold ctermfg=9 gui=bold guifg=#252525 guibg=#252525

if &t_Co > 255
  :highlight Normal ctermfg=250 ctermbg=234 cterm=NONE
  :hi CursorLine guifg=NONE guibg=#303030 gui=NONE cterm=NONE
  :highlight CursorLineNr ctermfg=215 ctermbg=NONE cterm=bold

  :highlight Boolean         ctermfg=135
  :highlight Character       ctermfg=144
  :highlight Number          ctermfg=135
  :highlight String          ctermfg=144
  :highlight Conditional     ctermfg=161               cterm=bold
  :highlight Constant        ctermfg=135               cterm=bold
  :highlight Cursor          ctermfg=16  ctermbg=253
  :highlight Debug           ctermfg=225               cterm=bold
  :highlight Define          ctermfg=81
  :highlight Delimiter       ctermfg=241

  :highlight DiffAdd                     ctermbg=24
  :highlight DiffChange      ctermfg=181 ctermbg=239
  :highlight DiffDelete      ctermfg=162 ctermbg=53
  :highlight DiffText ctermfg=16 ctermbg=188 cterm=NONE

  :highlight Directory ctermfg=109 ctermbg=NONE cterm=bold
  :highlight Error           ctermfg=219 ctermbg=89
  :highlight ErrorMsg        ctermfg=199 ctermbg=16    cterm=bold
  :highlight Exception       ctermfg=118               cterm=bold
  :highlight Float           ctermfg=135
  :highlight FoldColumn      ctermfg=67  ctermbg=16
  :highlight Folded          ctermfg=67  ctermbg=16
  :highlight Function        ctermfg=222
  :highlight Identifier ctermfg=109 ctermbg=NONE cterm=NONE
  :highlight Ignore          ctermfg=244 ctermbg=232
  :highlight IncSearch       ctermfg=193 ctermbg=16

  :highlight keyword         ctermfg=161               cterm=bold
  :highlight Label           ctermfg=229               cterm=none
  :highlight Macro           ctermfg=193
  :highlight SpecialKey      ctermfg=81

  :highlight MatchParen      ctermfg=233  ctermbg=208 cterm=bold
  :highlight ModeMsg         ctermfg=229
  :highlight MoreMsg         ctermfg=229
  :highlight Operator        ctermfg=161

  " complete menu
  :highlight Pmenu           ctermfg=81  ctermbg=16
  :highlight PmenuSel        ctermfg=255 ctermbg=242
  :highlight PmenuSbar                   ctermbg=232
  :highlight PmenuThumb      ctermfg=81

  :highlight PreCondit       ctermfg=118               cterm=bold
  :highlight PreProc         ctermfg=118
  :highlight Question        ctermfg=81
  :highlight Repeat          ctermfg=161               cterm=bold
  :highlight Search          ctermfg=0  ctermbg=222   cterm=NONE

  " marks column
  :highlight SignColumn      ctermfg=118 ctermbg=235
  :highlight SpecialChar     ctermfg=161               cterm=bold
  :highlight SpecialComment  ctermfg=245               cterm=bold
  :highlight Special         ctermfg=81
  if has("spell")
    :highlight SpellBad                ctermbg=52
    :highlight SpellCap                ctermbg=17
    :highlight SpellLocal              ctermbg=17
    :highlight SpellRare  ctermfg=none ctermbg=none  cterm=reverse
  endif
  :highlight Statement       ctermfg=161               cterm=bold
  :highlight StatusLine      ctermfg=238 ctermbg=253
  :highlight StatusLineNC    ctermfg=244 ctermbg=232
  :highlight StorageClass    ctermfg=208
  :highlight Structure       ctermfg=81
  :highlight Tag             ctermfg=161
  :highlight Title           ctermfg=166
  :highlight Todo            ctermfg=231 ctermbg=232   cterm=bold

  :highlight Typedef         ctermfg=81
  :highlight Type            ctermfg=81                cterm=none
  :highlight Underlined      ctermfg=244               cterm=underline

  :highlight VertSplit       ctermfg=244 ctermbg=232   cterm=bold
  :highlight VisualNOS                   ctermbg=238
  :highlight Visual                      ctermbg=235
  :highlight WarningMsg      ctermfg=231 ctermbg=238   cterm=bold
  :highlight WildMenu        ctermfg=81  ctermbg=16

  :highlight Comment         ctermfg=59
  :highlight CursorColumn                ctermbg=236
  :highlight ColorColumn                 ctermbg=236
  :highlight LineNr          ctermfg=250 ctermbg=236
  :highlight NonText         ctermfg=59

  :highlight SpecialKey      ctermfg=59

  if exists("g:rehash256") && g:rehash256 == 1
    "hi Normal       ctermfg=252 ctermbg=234
    :highlight Normal       ctermfg=252 ctermbg=none
    :highlight CursorLine               ctermbg=236   cterm=none
    :highlight CursorLineNr ctermfg=208               cterm=none

    :highlight Boolean         ctermfg=141
    :highlight Character ctermfg=151 ctermbg=NONE cterm=NONE
    :highlight Number          ctermfg=141
    :highlight String ctermfg=108 ctermbg=NONE cterm=NONE
    :highlight Conditional     ctermfg=197               cterm=bold
    :highlight Constant        ctermfg=141               cterm=bold

    :highlight DiffDelete      ctermfg=125 ctermbg=233

    :highlight Directory       ctermfg=154               cterm=bold
    :highlight Error           ctermfg=222 ctermbg=233
    :highlight Exception       ctermfg=154               cterm=bold
    :highlight Float           ctermfg=141
    :highlight Function        ctermfg=222
    :highlight Identifier      ctermfg=208

    :highlight Keyword         ctermfg=197               cterm=bold
    :highlight Operator        ctermfg=197
    :highlight PreCondit       ctermfg=154               cterm=bold
    :highlight PreProc         ctermfg=154
    :highlight Repeat          ctermfg=197               cterm=bold

    :highlight Statement       ctermfg=197               cterm=bold
    :highlight Tag             ctermfg=197
    :highlight Title           ctermfg=203
    :highlight Visual                      ctermbg=238

    :highlight Comment         ctermfg=244
    :highlight LineNr          ctermfg=239 ctermbg=235
    :highlight NonText         ctermfg=239
    :highlight SpecialKey      ctermfg=239
  endif

endif

:highlight Conceal ctermfg=7 ctermbg=8 guifg=LightGrey guibg=#263238
:highlight TabLineSel term=bold cterm=bold gui=bold
:highlight StatusLineTerm term=bold,reverse cterm=bold ctermfg=0 ctermbg=10 gui=bold guifg=bg guibg=LightGreen
:highlight StatusLineTermNC term=reverse ctermfg=0 ctermbg=10 guifg=bg guibg=LightGreen
:highlight lCursor guifg=bg guibg=fg
:highlight ToolbarLine term=underline ctermbg=8 guibg=Grey50
:highlight ToolbarButton cterm=bold ctermfg=0 ctermbg=7 gui=bold guifg=Black guibg=LightGrey
:highlight markdownHeadingDelimiter guifg=#ffb74d
:highlight htmlH1 gui=bold guifg=#ffb74d
:highlight htmlH2 gui=bold guifg=#ffb74d
:highlight htmlH3 guifg=#ffb74d
:highlight SyntasticError guifg=#e57373
:highlight SyntasticWarning guifg=#fdffdd
:highlight SyntasticErrorSign gui=bold guifg=#e57373
:highlight SyntasticWarningSign gui=bold guifg=#fdffdd
:highlight Terminal guifg=#bcbcbc guibg=#1c1c1c
set background=dark
