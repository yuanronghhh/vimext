" Vim color file
"
" Author: Tomas Restrepo <tomas@winterdom.com>
" https://github.com/tomasr/molokai
"
" Note: Based on the Monokai theme for TextMate
" by Wimer Hazenberg and its darker variant
" by Hamish Stuart Macpherson
"

hi clear

if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    :highlight clear
    if exists("syntax_on")
        syntax reset
    endif
endif
let g:colors_name="molokai"

if exists("g:molokai_original")
    let s:molokai_original = g:molokai_original
else
    let s:molokai_original = 0
endif


hi Boolean         guifg=#AE81FF
hi Character       guifg=#E6DB74
hi Number          guifg=#AE81FF
hi String          guifg=#E6DB74
hi Conditional     guifg=#F92672               gui=bold
hi Constant        guifg=#AE81FF               gui=bold
hi Cursor          guifg=#000000 guibg=#F8F8F0
hi iCursor         guifg=#000000 guibg=#F8F8F0
hi Debug           guifg=#BCA3A3               gui=bold
hi Define          guifg=#66D9EF
hi Delimiter       guifg=#8F8F8F
hi DiffAdd                       guibg=#13354A
hi DiffChange      guifg=#89807D guibg=#4C4745
hi DiffDelete      guifg=#960050 guibg=#1E0010
hi DiffText                      guibg=#4C4745 gui=none,bold

hi Directory       guifg=#A6E22E               gui=bold
hi Error           guifg=#E6DB74 guibg=#1E0010
hi ErrorMsg        guifg=#F92672 guibg=#232526 gui=bold
hi Exception       guifg=#A6E22E               gui=bold
hi Float           guifg=#AE81FF
hi FoldColumn      guifg=#465457 guibg=#000000
hi Folded          guifg=#465457 guibg=#000000
hi Function        guifg=#A6E22E
hi Identifier      guifg=#FD971F
hi Ignore          guifg=#808080 guibg=bg
hi IncSearch       guifg=#C4BE89 guibg=#000000

hi Keyword         guifg=#F92672               gui=bold
hi Label           guifg=#E6DB74               gui=none
hi Macro           guifg=#C4BE89               gui=none
hi SpecialKey      guifg=#66D9EF               gui=none

hi MatchParen      guifg=#000000 guibg=#FD971F gui=bold
hi ModeMsg         guifg=#E6DB74
hi MoreMsg         guifg=#E6DB74
hi Operator        guifg=#F92672

" complete menu
hi Pmenu           guifg=#66D9EF guibg=#000000
hi PmenuSel                      guibg=#808080
hi PmenuSbar                     guibg=#080808
hi PmenuThumb      guifg=#66D9EF

hi PreCondit       guifg=#A6E22E               gui=bold
hi PreProc         guifg=#A6E22E
hi Question        guifg=#66D9EF
hi Repeat          guifg=#F92672               gui=bold
hi Search          guifg=#000000 guibg=#FFE792
" marks
hi SignColumn      guifg=#A6E22E guibg=#232526
hi SpecialChar     guifg=#F92672               gui=bold
hi SpecialComment  guifg=#7E8E91               gui=bold
hi Special         guifg=#66D9EF guibg=bg      gui=none
if has("spell")
    :highlight SpellBad    guisp=#FF0000 gui=undercurl
    :highlight SpellCap    guisp=#7070F0 gui=undercurl
    :highlight SpellLocal  guisp=#70F0F0 gui=undercurl
    :highlight SpellRare   guisp=#FFFFFF gui=undercurl
endif
hi Statement       guifg=#F92672               gui=bold
hi StatusLine      guifg=#455354 guibg=fg
hi StatusLineNC    guifg=#808080 guibg=#080808
hi StorageClass    guifg=#FD971F               gui=none
hi Structure       guifg=#66D9EF
hi Tag             guifg=#F92672               gui=none
hi Title           guifg=#ef5939
hi Todo            guifg=#FFFFFF guibg=bg      gui=bold

hi Typedef         guifg=#66D9EF
hi Type            guifg=#66D9EF               gui=none
hi Underlined      guifg=#808080               gui=underline

hi VertSplit       guifg=#808080 guibg=#080808 gui=bold
hi VisualNOS                     guibg=#403D3D
hi Visual                        guibg=#403D3D
hi WarningMsg      guifg=#FFFFFF guibg=#333333 gui=bold
hi WildMenu        guifg=#66D9EF guibg=#000000

hi TabLineFill     guifg=#1B1D1E guibg=#1B1D1E
hi TabLine         guibg=#1B1D1E guifg=#808080 gui=none

if s:molokai_original == 1
   "hi Normal          guifg=#F8F8F2 guibg=#272822
   :highlight Normal          guifg=#F8F8F2 guibg=none
   :highlight Comment         guifg=#75715E
   :highlight CursorLine                    guibg=#3E3D32
   :highlight CursorLineNr    guifg=#FD971F               gui=none
   :highlight CursorColumn                  guibg=#3E3D32
   :highlight ColorColumn                   guibg=#3B3A32
   :highlight LineNr          guifg=#BCBCBC guibg=#3B3A32
   :highlight NonText         guifg=#75715E
   :highlight SpecialKey      guifg=#75715E
else
   :highlight Normal          guifg=#F8F8F2 guibg=#1B1D1E
   :highlight Comment         guifg=#7E8E91
   :highlight CursorLine                    guibg=#293739
   :highlight CursorLineNr    guifg=#FD971F               gui=none
   :highlight CursorColumn                  guibg=#293739
   :highlight ColorColumn                   guibg=#232526
   :highlight LineNr          guifg=#465457 guibg=#232526
   :highlight NonText         guifg=#465457
   :highlight SpecialKey      guifg=#465457
end

"
" Support for 256-color terminal
"
if &t_Co > 255
   if s:molokai_original == 1
      "hi Normal                   ctermbg=234
      :highlight Normal                   ctermbg=none
      :highlight CursorLine               ctermbg=235   cterm=none
      :highlight CursorLineNr ctermfg=208               cterm=none
   else
      "hi Normal       ctermfg=252 ctermbg=233
      :highlight Normal       ctermfg=252 ctermbg=none
      :highlight CursorLine               ctermbg=234   cterm=none
      :highlight CursorLineNr ctermfg=208               cterm=none
   endif
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
   :highlight DiffText                    ctermbg=102 cterm=bold

   :highlight Directory       ctermfg=118               cterm=bold
   :highlight Error           ctermfg=219 ctermbg=89
   :highlight ErrorMsg        ctermfg=199 ctermbg=16    cterm=bold
   :highlight Exception       ctermfg=118               cterm=bold
   :highlight Float           ctermfg=135
   :highlight FoldColumn      ctermfg=67  ctermbg=16
   :highlight Folded          ctermfg=67  ctermbg=16
   :highlight Function        ctermfg=118
   :highlight Identifier      ctermfg=208               cterm=none
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
       :highlight Character       ctermfg=222
       :highlight Number          ctermfg=141
       :highlight String          ctermfg=222
       :highlight Conditional     ctermfg=197               cterm=bold
       :highlight Constant        ctermfg=141               cterm=bold

       :highlight DiffDelete      ctermfg=125 ctermbg=233

       :highlight Directory       ctermfg=154               cterm=bold
       :highlight Error           ctermfg=222 ctermbg=233
       :highlight Exception       ctermfg=154               cterm=bold
       :highlight Float           ctermfg=141
       :highlight Function        ctermfg=154
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
end

" Must be at the end, because of ctermbg=234 bug.
" https://groups.google.com/forum/#!msg/vim_dev/afPqwAFNdrU/nqh6tOM87QUJ
set background=dark
