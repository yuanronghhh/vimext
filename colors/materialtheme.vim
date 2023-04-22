set background=dark

hi clear

if exists("syntax_on")
     syntax reset
endif

let g:colors_name="materialtheme"

hi SpecialKey term=bold ctermfg=9 guifg=#ffffff guibg=#263238
hi NonText term=bold ctermfg=9 gui=bold guifg=#252525 guibg=#252525
hi Directory term=bold ctermfg=11 gui=bold guifg=#8a8a8a
hi ErrorMsg term=standout ctermfg=15 ctermbg=4 gui=bold guifg=#F92672 guibg=#232526
hi IncSearch term=reverse cterm=reverse gui=reverse guifg=#C4BE89 guibg=#000000
hi Search term=reverse cterm=underline ctermfg=0 ctermbg=14 gui=underline guifg=#fdffdd guibg=#463238
hi MoreMsg term=bold ctermfg=10 gui=bold guifg=#E6DB74
hi ModeMsg term=bold cterm=bold gui=bold guifg=#E6DB74
hi LineNr term=underline ctermfg=14 guifg=#939393 guibg=#000000
hi CursorLineNr term=bold ctermfg=14 guifg=#FD971F
hi Question term=standout ctermfg=10 gui=bold guifg=#66D9EF
hi StatusLine term=bold,reverse cterm=bold,reverse gui=bold,reverse guifg=#000000 guibg=#ffffff
hi StatusLineNC term=reverse cterm=reverse gui=reverse guifg=#222222 guibg=#ffffff
hi VertSplit term=reverse cterm=reverse gui=bold guifg=#252525 guibg=#252525
hi Title term=bold ctermfg=13 gui=bold guifg=#ffb74d
hi Visual term=reverse cterm=reverse ctermfg=208 guifg=#ffffff guibg=#037655
hi VisualNOS term=bold,underline cterm=bold,underline gui=bold,underline guibg=#403D3D
hi WarningMsg term=standout ctermfg=12 gui=bold guifg=#FFFFFF guibg=#333333
hi WildMenu term=standout ctermfg=0 ctermbg=14 guifg=#66D9EF guibg=#000000
hi Folded term=standout ctermfg=11 ctermbg=8 guifg=#80cbc4 guibg=#37474f
hi FoldColumn term=standout ctermfg=11 ctermbg=8 gui=bold guifg=#afafdf guibg=#263238
hi DiffAdd term=bold ctermbg=1 guibg=#13354A
hi DiffChange term=bold ctermbg=5 guifg=#89807D guibg=#4C4745
hi DiffDelete term=bold ctermfg=9 ctermbg=3 gui=bold guifg=#960050 guibg=#1E0010
hi DiffText term=reverse cterm=bold ctermbg=12 gui=bold guibg=#4C4745
hi SignColumn term=standout ctermfg=11 ctermbg=8 guifg=#A6E22E guibg=#263238
hi Conceal ctermfg=7 ctermbg=8 guifg=LightGrey guibg=#263238
hi SpellBad term=reverse ctermbg=12 gui=undercurl guifg=#e57373 guisp=#e57373
hi SpellCap term=reverse ctermbg=9 gui=undercurl guisp=#7070F0
hi SpellRare term=reverse ctermbg=13 gui=undercurl guisp=#FFFFFF
hi SpellLocal term=underline ctermbg=11 gui=undercurl guisp=#70F0F0
hi Pmenu ctermfg=0 ctermbg=13 guifg=#80cbc4 guibg=#37474f
hi PmenuSel ctermfg=8 ctermbg=0 guifg=#afddff guibg=#363838
hi PmenuSbar ctermbg=7 guibg=#080808
hi PmenuThumb ctermbg=15 guifg=#66D9EF guibg=White
hi TabLine term=underline cterm=underline ctermfg=15 ctermbg=8 guifg=#808080 guibg=#1B1D1E
hi TabLineSel term=bold cterm=bold gui=bold
hi TabLineFill term=reverse cterm=reverse gui=reverse guifg=#1B1D1E guibg=#263238
hi CursorColumn term=reverse ctermbg=8 guibg=#373737
hi CursorLine term=underline cterm=underline guibg=#373737
hi ColorColumn term=reverse ctermbg=4 guifg=#ffffff guibg=#1c1c1c
hi StatusLineTerm term=bold,reverse cterm=bold ctermfg=0 ctermbg=10 gui=bold guifg=bg guibg=LightGreen
hi StatusLineTermNC term=reverse ctermfg=0 ctermbg=10 guifg=bg guibg=LightGreen
hi Cursor guifg=#037655 guibg=#ffffff
hi lCursor guifg=bg guibg=fg
hi MatchParen term=reverse ctermbg=3 gui=bold guifg=#ffb74d guibg=#37473f
hi Normal guifg=#dcdcdc guibg=#252525
hi ToolbarLine term=underline ctermbg=8 guibg=Grey50
hi ToolbarButton cterm=bold ctermfg=0 ctermbg=7 gui=bold guifg=Black guibg=LightGrey
hi Function guifg=#dfafdf
hi String guifg=#80cbc4
hi Comment term=bold ctermfg=7 guifg=#afafaf
hi Todo term=standout ctermfg=0 ctermbg=14 gui=bold guifg=#80cbc4 guibg=#37474f
hi Constant term=underline ctermfg=13 gui=bold guifg=#ffffff guibg=#434343
hi Type term=underline ctermfg=10 guifg=#aed2d3
hi Statement term=bold ctermfg=14 gui=bold guifg=#ffdf87
hi Identifier term=underline cterm=bold ctermfg=11 guifg=#AD7FA8
hi PreProc term=underline ctermfg=9 guifg=#e9ba6e
hi Special term=underline ctermfg=12 guifg=#64b5f6 guibg=bg
hi Number gui=bold guifg=#fdffdd
hi Delimiter guifg=#8787df
hi markdownHeadingDelimiter guifg=#ffb74d
hi htmlH1 gui=bold guifg=#ffb74d
hi htmlH2 gui=bold guifg=#ffb74d
hi htmlH3 guifg=#ffb74d
hi SyntasticError guifg=#e57373
hi SyntasticWarning guifg=#fdffdd
hi SyntasticErrorSign gui=bold guifg=#e57373
hi SyntasticWarningSign gui=bold guifg=#fdffdd
hi Error term=reverse ctermfg=15 ctermbg=12 guifg=#E6DB74 guibg=#1E0010

hi link EndOfBuffer NonText
hi link QuickFixLine Search
hi link htmlItalic Normal
hi link cmakeTodo Todo
hi link cmakeLuaComment Comment
hi link cmakeComment Comment
hi link cmakeEscaped Special
hi link cmakeRegistry Underlined
hi link cmakeVariableValue Type
hi link cmakeProperty Constant
hi link cmakeGeneratorExpressions Constant
hi link cmakeGeneratorExpression WarningMsg
hi link cmakeString String
hi link cmakeVariable Identifier
hi link cmakeEnvironment Special
hi link cmakeCommand Function
hi link cmakeCommandConditional Conditional
hi link cmakeCommandRepeat Repeat
hi link cmakeCommandDeprecated WarningMsg
hi clear cmakeArguments
hi link cmakeModule Include
hi link cmakeKWExternalProject ModeMsg
hi link cmakeKWadd_compile_options ModeMsg
hi link cmakeKWadd_custom_command ModeMsg
hi link cmakeKWadd_custom_target ModeMsg
hi link cmakeKWadd_definitions ModeMsg
hi link cmakeKWadd_dependencies ModeMsg
hi link cmakeKWadd_executable ModeMsg
hi link cmakeKWadd_library ModeMsg
hi link cmakeKWadd_subdirectory ModeMsg
hi link cmakeKWadd_test ModeMsg
hi link cmakeKWbuild_command ModeMsg
hi link cmakeKWbuild_name ModeMsg
hi link cmakeKWcmake_host_system_information ModeMsg
hi link cmakeKWcmake_minimum_required ModeMsg
hi link cmakeKWcmake_parse_arguments ModeMsg
hi link cmakeKWcmake_policy ModeMsg
hi link cmakeKWconfigure_file ModeMsg
hi link cmakeKWcreate_test_sourcelist ModeMsg
hi link cmakeKWctest_build ModeMsg
hi link cmakeKWctest_configure ModeMsg
hi link cmakeKWctest_coverage ModeMsg
hi link cmakeKWctest_memcheck ModeMsg
hi link cmakeKWctest_run_script ModeMsg
hi link cmakeKWctest_start ModeMsg
hi link cmakeKWctest_submit ModeMsg
hi link cmakeKWctest_test ModeMsg
hi link cmakeKWctest_update ModeMsg
hi link cmakeKWctest_upload ModeMsg
hi link cmakeKWdefine_property ModeMsg
hi link cmakeKWenable_language ModeMsg
hi link cmakeKWexec_program ModeMsg
hi link cmakeKWexecute_process ModeMsg
hi link cmakeKWexport ModeMsg
hi link cmakeKWexport_library_dependencies ModeMsg
hi link cmakeKWfile ModeMsg
hi link cmakeKWfind_file ModeMsg
hi link cmakeKWfind_library ModeMsg
hi link cmakeKWfind_package ModeMsg
hi link cmakeKWfind_path ModeMsg
hi link cmakeKWfind_program ModeMsg
hi link cmakeKWfltk_wrap_ui ModeMsg
hi link cmakeKWforeach ModeMsg
hi link cmakeKWfunction ModeMsg
hi link cmakeKWget_cmake_property ModeMsg
hi link cmakeKWget_directory_property ModeMsg
hi link cmakeKWget_filename_component ModeMsg
hi link cmakeKWget_property ModeMsg
hi link cmakeKWget_source_file_property ModeMsg
hi link cmakeKWget_target_property ModeMsg
hi link cmakeKWget_test_property ModeMsg
hi link cmakeKWif ModeMsg
hi link cmakeKWinclude ModeMsg
hi link cmakeKWinclude_directories ModeMsg
hi link cmakeKWinclude_external_msproject ModeMsg
hi link cmakeKWinclude_guard ModeMsg
hi link cmakeKWinstall ModeMsg
hi link cmakeKWinstall_files ModeMsg
hi link cmakeKWinstall_programs ModeMsg
hi link cmakeKWinstall_targets ModeMsg
hi link cmakeKWlist ModeMsg
hi link cmakeKWload_cache ModeMsg
hi link cmakeKWload_command ModeMsg
hi link cmakeKWmacro ModeMsg
hi link cmakeKWmake_directory ModeMsg
hi link cmakeKWmark_as_advanced ModeMsg
hi link cmakeKWmath ModeMsg
hi link cmakeKWmessage ModeMsg
hi link cmakeKWoption ModeMsg
hi link cmakeKWproject ModeMsg
hi link cmakeKWremove ModeMsg
hi link cmakeKWseparate_arguments ModeMsg
hi link cmakeKWset ModeMsg
hi link cmakeKWset_directory_properties ModeMsg
hi link cmakeKWset_property ModeMsg
hi link cmakeKWset_source_files_properties ModeMsg
hi link cmakeKWset_target_properties ModeMsg
hi link cmakeKWset_tests_properties ModeMsg
hi link cmakeKWsource_group ModeMsg
hi link cmakeKWstring ModeMsg
hi link cmakeKWsubdirs ModeMsg
hi link cmakeKWtarget_compile_definitions ModeMsg
hi link cmakeKWtarget_compile_features ModeMsg
hi link cmakeKWtarget_compile_options ModeMsg
hi link cmakeKWtarget_include_directories ModeMsg
hi link cmakeKWtarget_link_libraries ModeMsg
hi link cmakeKWtarget_sources ModeMsg
hi link cmakeKWtry_compile ModeMsg
hi link cmakeKWtry_run ModeMsg
hi link cmakeKWunset ModeMsg
hi link cmakeKWuse_mangled_mesa ModeMsg
hi link cmakeKWvariable_requires ModeMsg
hi link cmakeKWvariable_watch ModeMsg
hi link cmakeKWwhile ModeMsg
hi link cmakeKWwrite_file ModeMsg
hi Conditional gui=bold guifg=#F92672
hi Repeat gui=bold guifg=#F92672
hi link Include PreProc
hi Underlined term=underline cterm=underline ctermfg=9 gui=underline guifg=#808080
hi link ALEErrorSign Error
hi link ALEStyleErrorSign ALEErrorSign
hi link ALEWarningSign Todo
hi link ALEStyleWarningSign ALEWarningSign
hi link ALEInfoSign ALEWarningSign
hi link ALESignColumnWithErrors Error
hi clear ALESignColumnWithoutErrors
hi clear ALEErrorLine
hi clear ALEWarningLine
hi clear ALEInfoLine
hi link ALEError SpellBad
hi link ALEStyleError ALEError
hi link ALEWarning SpellCap
hi link ALEStyleWarning ALEWarning
hi link ALEInfo ALEWarning
hi link NERDTreeIgnore ignore
hi link NERDTreeUp Directory
hi link NERDTreeHelpKey Identifier
hi link NERDTreeHelpTitle Macro
hi link NERDTreeToggleOn Question
hi link NERDTreeToggleOff WarningMsg
hi link NERDTreeHelpCommand Identifier
hi link NERDTreeHelp String
hi link NERDTreeDir Directory
hi link NERDTreeFile Normal
hi link NERDTreeLinkTarget Type
hi link NERDTreeLinkFile Macro
hi link NERDTreeLinkDir Macro
hi link NERDTreeDirSlash Identifier
hi link NERDTreeClosable Directory
hi link NERDTreeOpenable Directory
hi link NERDTreeRO WarningMsg
hi link NERDTreeBookmark Normal
hi link NERDTreeExecFile Title
hi clear NERDTreeLink
hi link NERDTreeFlags Number
hi link NERDTreeCWD Statement
hi link NERDTreeBookmarksLeader ignore
hi link NERDTreeBookmarksHeader Statement
hi link NERDTreeBookmarkName Identifier
hi link NERDTreePart Special
hi link NERDTreePartFile Type
hi ignore ctermfg=0 guifg=#808080 guibg=bg
hi Macro guifg=#C4BE89
hi link NERDTreeCurrentNode Search
hi link shDoError Error
hi link shIfError Error
hi link shInError Error
hi link shCaseError Error
hi link shEsacError Error
hi link shCurlyError Error
hi link shParenError Error
hi link shTestError Error
hi clear shOK
hi link shArithmetic Special
hi clear shCaseEsac
hi link shComment Comment
hi link shDeref shShellVariables
hi clear shDo
hi link shDerefSimple shDeref
hi link shEcho shString
hi link shEscape shCommandSub
hi link shNumber Number
hi link shOperator Operator
hi link shPosnParm shShellVariables
hi link shExSingleQuote shSingleQuote
hi link shExDoubleQuote shDoubleQuote
hi link shHereString shRedir
hi link shRedir shOperator
hi link shSingleQuote shString
hi link shDoubleQuote shString
hi link shStatement Statement
hi link shVariable shSetList
hi link shAlias Identifier
hi clear shTest
hi link shCtrlSeq Special
hi link shSpecial Special
hi link shParen shArithmetic
hi clear bashSpecialVariables
hi clear bashStatement
hi clear shIf
hi clear shFor
hi link shCaseStart shConditional
hi clear shCase
hi link shCaseBar shConditional
hi link shCaseIn shConditional
hi link shCaseCommandSub shCommandSub
hi clear shCaseExSingleQuote
hi link shCaseSingleQuote shSingleQuote
hi link shCaseDoubleQuote shDoubleQuote
hi link shStringSpecial shSpecial
hi clear shCaseRange
hi link shColon shComment
hi link shCommandSub Special
hi clear shExpr
hi link shHereDoc shString
hi link shSetList Identifier
hi link shSource shOperator
hi clear shCmdParenRegion
hi link shOption shCommandSub
hi clear shSubSh
hi clear shComma
hi link shDerefSpecial shDeref
hi link shDerefVar shDeref
hi link shDerefWordError Error
hi link shDerefPSR shDerefOp
hi link shDerefPPS shDerefOp
hi clear shDerefOff
hi link shDerefOp shOperator
hi clear shDerefVarArray
hi link shDerefOpError Error
hi link shEchoQuote shString
hi link shCharClass Identifier
hi clear shDblBrace
hi link shBeginHere shRedir
hi link shHerePayload shHereDoc
hi link shWrapLineOperator shOperator
hi link shSetOption shOption
hi link shAtExpr shSetList
hi clear shDblParen
hi link shFunctionKey Function
hi clear shFunctionOne
hi clear shFunctionTwo
hi link shConditional Conditional
hi link shForPP shLoop
hi link shSet Statement
hi link shTestOpr shConditional
hi clear shTouch
hi link shSpecialNoZS shSpecial
hi link shEchoDelim shOperator
hi link shQuickComment shComment
hi clear shSpecialVar
hi link shEmbeddedEcho shString
hi link shTouchCmd shStatement
hi link shPattern shString
hi link shExprRegion Delimiter
hi link shSpecialNxt shSpecial
hi link shSubShRegion shOperator
hi link shRange shOperator
hi link shNoQuote shDoubleQuote
hi link shString String
hi link shAstQuote shDoubleQuote
hi link shTestDoubleQuote shString
hi link shTestSingleQuote shString
hi link shTestPattern shString
hi link shLoop shStatement
hi clear shCurlyIn
hi link shRepeat Repeat
hi link shSnglCase Statement
hi link shQuote shOperator
hi link shCmdSubRegion shShellVariables
hi link shSpecialStart shSpecial
hi clear shBkslshSnglQuote
hi clear shBkslshDblQuote
hi link shTodo Todo
hi link shHereDoc01 shRedir
hi link shHereDoc02 shRedir
hi link shHereDoc03 shRedir
hi link shHereDoc04 shRedir
hi link shHereDoc05 shRedir
hi link shHereDoc06 shRedir
hi link shHereDoc07 shRedir
hi link shHereDoc08 shRedir
hi link shHereDoc09 shRedir
hi link shHereDoc10 shRedir
hi link shHereDoc11 shRedir
hi link shHereDoc12 shRedir
hi link shHereDoc13 shRedir
hi link shHereDoc14 shRedir
hi link shHereDoc15 shRedir
hi clear shVarAssign
hi link shSetListDelim shOperator
hi link shFunction Function
hi clear shFunctionStart
hi clear shFunctionThree
hi clear shFunctionFour
hi clear shDerefPattern
hi link shDerefString shDoubleQuote
hi clear shDerefEscape
hi link shDerefDelim shOperator
hi clear shDerefLen
hi clear shDerefPPSleft
hi clear shDerefPPSright
hi clear shDerefPSRleft
hi clear shDerefPSRright
hi link shArithRegion shShellVariables
hi link shCondError Error
hi clear shCaseEsacSync
hi clear shDoSync
hi clear shForSync
hi clear shIfSync
hi clear shUntilSync
hi clear shWhileSync
hi link shShellVariables PreProc
hi link shDerefPOL shDerefOp
hi link shFunctionName Function
hi Operator guifg=#F92672
hi link cStatement Statement
hi link cLabel Label
hi link cConditional Conditional
hi link cRepeat Repeat
hi link cTodo Todo
hi link cBadContinuation Error
hi link cSpecial SpecialChar
hi link cFormat cSpecial
hi link cString String
hi link cCppString cString
hi link cSpaceError cError
hi clear cCppSkip
hi link cCharacter Character
hi link cSpecialError cError
hi link cSpecialCharacter cSpecial
hi clear cBadBlock
hi link cCurlyError cError
hi link cErrInParen cError
hi clear cCppParen
hi link cErrInBracket cError
hi clear cCppBracket
hi clear cBlock
hi link cParenError cError
hi link cIncluded cString
hi link cCommentSkip cComment
hi link cCommentString cString
hi link cComment2String cString
hi link cCommentStartError cError
hi link cUserLabel Label
hi clear cBitField
hi link cOctalZero PreProc
hi link cNumber Number
hi link cFloat Float
hi link cOctal Number
hi link cOctalError cError
hi clear cNumbersCom
hi clear cParen
hi clear cBracket
hi clear cNumbers
hi link cCommentL cComment
hi link cCommentStart cComment
hi link cComment Comment
hi link cCommentError cError
hi link cOperator Operator
hi link cType Type
hi link cStructure Structure
hi link cStorageClass StorageClass
hi link cConstant Constant
hi link cPreCondit PreCondit
hi link cPreConditMatch cPreCondit
hi clear cCppInIf
hi clear cCppInElse
hi link cCppInElse2 cCppOutIf2
hi clear cCppOutIf
hi link cCppOutIf2 cCppOut
hi clear cCppOutElse
hi clear cCppInSkip
hi link cCppOutSkip cCppOutIf2
hi link cCppOutWrapper cPreCondit
hi link cCppInWrapper cCppOutWrapper
hi link cPreProc PreProc
hi link cInclude Include
hi link cDefine Macro
hi clear cMulti
hi clear cUserCont
hi Label guifg=#E6DB74
hi Character guifg=#E6DB74
hi Float guifg=#AE81FF
hi link cError Error
hi Structure guifg=#66D9EF
hi StorageClass guifg=#FD971F
hi PreCondit gui=bold guifg=#A6E22E
hi SpecialChar gui=bold guifg=#F92672
hi link cCppOut Comment
hi link cppStatement Statement
hi link cppAccess cppStatement
hi link cppModifier Type
hi link cppType Type
hi link cppExceptions Exception
hi link cppOperator Operator
hi link cppCast cppStatement
hi link cppStorageClass StorageClass
hi link cppStructure Structure
hi link cppBoolean Boolean
hi link cppConstant Constant
hi link cppRawStringDelimiter Delimiter
hi link cppRawString String
hi link cppNumber Number
hi clear cppMinMax
hi Exception gui=bold guifg=#A6E22E
hi Boolean guifg=#AE81FF
hi clear multiple_cursors_cursor
hi link multiple_cursors_visual Visual
hi Keyword gui=bold guifg=#F92672
hi Define guifg=#66D9EF
hi Typedef guifg=#66D9EF
hi Tag guifg=#F92672
hi SpecialComment gui=bold guifg=#7E8E91
hi Debug gui=bold guifg=#BCA3A3
hi iCursor guifg=#000000 guibg=#F8F8F0
hi link vimTodo Todo
hi link vimCommand Statement
hi clear vimStdPlugin
hi link vimOption PreProc
hi link vimErrSetting vimError
hi link vimAutoEvent Type
hi link vimGroup Type
hi link vimHLGroup vimGroup
hi link vimFuncName Function
hi clear vimGlobal
hi link vimSubst vimCommand
hi link vimNumber Number
hi link vimAddress vimMark
hi link vimAutoCmd vimCommand
hi clear vimIsCommand
hi clear vimExtCmd
hi clear vimFilter
hi link vimLet vimCommand
hi link vimMap vimCommand
hi link vimMark Number
hi clear vimSet
hi link vimSyntax vimCommand
hi clear vimUserCmd
hi clear vimCmdSep
hi link vimVar Identifier
hi link vimFBVar vimVar
hi link vimInsert vimString
hi link vimBehaveModel vimBehave
hi link vimBehaveError vimError
hi link vimBehave vimCommand
hi link vimFTCmd vimCommand
hi link vimFTOption vimSynType
hi link vimFTError vimError
hi clear vimFiletype
hi clear vimAugroup
hi clear vimExecute
hi link vimNotFunc vimCommand
hi clear vimFunction
hi link vimFunctionError vimError
hi link vimLineComment vimComment
hi link vimSpecFile Identifier
hi link vimOper Operator
hi clear vimOperParen
hi link vimComment Comment
hi link vimString String
hi link vimRegister SpecialChar
hi link vimCmplxRepeat SpecialChar
hi clear vimRegion
hi clear vimSynLine
hi link vimNotation Special
hi link vimCtrlChar SpecialChar
hi link vimFuncVar Identifier
hi link vimContinue Special
hi clear vimSetEqual
hi link vimAugroupKey vimCommand
hi link vimAugroupError vimError
hi link vimEnvvar PreProc
hi link vimFunc vimError
hi link vimParenSep Delimiter
hi link vimSep Delimiter
hi link vimOperError Error
hi link vimFuncKey vimCommand
hi link vimFuncSID Special
hi link vimAbb vimCommand
hi clear vimEcho
hi link vimEchoHL vimCommand
hi clear vimIf
hi link vimHighlight vimCommand
hi link vimNorm vimCommand
hi link vimUnmap vimMap
hi link vimUserCommand vimCommand
hi clear vimFuncBody
hi clear vimFuncBlank
hi link vimPattern Type
hi link vimSpecFileMod vimSpecFile
hi clear vimEscapeBrace
hi link vimSetString vimString
hi clear vimSubstRep
hi clear vimSubstRange
hi link vimUserAttrb vimSpecial
hi link vimUserAttrbError Error
hi link vimUserAttrbKey vimOption
hi link vimUserAttrbCmplt vimSpecial
hi link vimUserCmdError Error
hi link vimUserAttrbCmpltFunc Special
hi link vimCommentString vimString
hi link vimPatSepErr vimPatSep
hi link vimPatSep SpecialChar
hi link vimPatSepZ vimPatSep
hi link vimPatSepZone vimString
hi link vimPatSepR vimPatSep
hi clear vimPatRegion
hi link vimNotPatSep vimString
hi link vimStringCont vimString
hi link vimSubstTwoBS vimString
hi link vimSubstSubstr SpecialChar
hi clear vimCollection
hi clear vimSubstPat
hi link vimSubst1 vimSubst
hi link vimSubstDelim Delimiter
hi clear vimSubstRep4
hi link vimSubstFlagErr vimError
hi clear vimCollClass
hi link vimCollClassErr vimError
hi link vimSubstFlags Special
hi link vimMarkNumber vimNumber
hi link vimPlainMark vimMark
hi link vimPlainRegister vimRegister
hi link vimSetMod vimOption
hi link vimSetSep Statement
hi link vimMapMod vimBracket
hi clear vimMapLhs
hi clear vimAutoCmdSpace
hi clear vimAutoEventList
hi clear vimAutoCmdSfxList
hi link vimEchoHLNone vimGroup
hi link vimMapBang vimCommand
hi clear vimMapRhs
hi link vimMapModKey vimFuncSID
hi link vimMapModErr vimError
hi clear vimMapRhsExtend
hi clear vimMenuBang
hi clear vimMenuPriority
hi link vimMenuName PreProc
hi link vimMenuMod vimMapMod
hi link vimMenuNameMore vimMenuName
hi clear vimMenuMap
hi clear vimMenuRhs
hi link vimBracket Delimiter
hi link vimUserFunc Normal
hi link vimElseIfErr Error
hi link vimBufnrWarn vimWarn
hi clear vimNormCmds
hi link vimGroupSpecial Special
hi clear vimGroupList
hi link vimSynError Error
hi link vimSynContains vimSynOption
hi link vimSynKeyContainedin vimSynContains
hi link vimSynNextgroup vimSynOption
hi link vimSynType vimSpecial
hi clear vimAuSyntax
hi link vimSynCase Type
hi link vimSynCaseError vimError
hi clear vimClusterName
hi link vimGroupName vimGroup
hi link vimGroupAdd vimSynOption
hi link vimGroupRem vimSynOption
hi clear vimIskList
hi link vimIskSep Delimiter
hi link vimSynKeyOpt vimSynOption
hi clear vimSynKeyRegion
hi link vimMtchComment vimComment
hi link vimSynMtchOpt vimSynOption
hi link vimSynRegPat vimString
hi clear vimSynMatchRegion
hi clear vimSynMtchCchar
hi clear vimSynMtchGroup
hi link vimSynPatRange vimString
hi link vimSynNotPatRange vimSynRegPat
hi link vimSynRegOpt vimSynOption
hi link vimSynReg Type
hi link vimSynMtchGrp vimSynOption
hi clear vimSynRegion
hi clear vimSynPatMod
hi link vimSyncC Type
hi clear vimSyncLines
hi clear vimSyncMatch
hi link vimSyncError Error
hi clear vimSyncLinebreak
hi clear vimSyncLinecont
hi clear vimSyncRegion
hi link vimSyncGroupName vimGroupName
hi link vimSyncKey Type
hi link vimSyncGroup vimGroupName
hi link vimSyncNone Type
hi clear vimHiLink
hi link vimHiClear vimHighlight
hi clear vimHiKeyList
hi link vimHiCtermError vimError
hi clear vimHiBang
hi link vimHiGroup vimGroupName
hi link vimHiAttrib PreProc
hi link vimFgBgAttrib vimHiAttrib
hi link vimHiAttribList vimError
hi clear vimHiCtermColor
hi clear vimHiFontname
hi clear vimHiGuiFontname
hi link vimHiGuiRgb vimNumber
hi link vimHiTerm Type
hi link vimHiCTerm vimHiTerm
hi link vimHiStartStop vimHiTerm
hi link vimHiCtermFgBg vimHiTerm
hi link vimHiGui vimHiTerm
hi link vimHiGuiFont vimHiTerm
hi link vimHiGuiFgBg vimHiTerm
hi link vimHiKeyError vimError
hi clear vimHiTermcap
hi link vimHiNmbr Number
hi link vimCommentTitle PreProc
hi clear vimCommentTitleLeader
hi link vimSearchDelim Statement
hi link vimSearch vimString
hi link vimEmbedError vimError
hi clear vimPythonRegion
hi link pythonStatement Statement
hi link pythonFunction Function
hi link pythonConditional Conditional
hi link pythonRepeat Repeat
hi link pythonOperator Operator
hi link pythonException Exception
hi link pythonInclude Include
hi link pythonAsync Statement
hi link pythonDecorator Define
hi link pythonDecoratorName Function
hi link pythonDoctestValue Define
hi clear pythonMatrixMultiply
hi link pythonTodo Todo
hi link pythonComment Comment
hi link pythonQuotes String
hi link pythonEscape Special
hi link pythonString String
hi link pythonTripleQuotes pythonQuotes
hi clear pythonSpaceError
hi link pythonDoctest Special
hi link pythonRawString String
hi link pythonNumber Number
hi link pythonBuiltin Function
hi clear pythonAttribute
hi link pythonExceptions Structure
hi clear pythonSync
hi link vimScriptDelim Comment
hi clear vimAugroupSyncA
hi link vimError Error
hi link vimKeyCodeError vimError
hi link vimWarn WarningMsg
hi link vimAuHighlight vimHighlight
hi link vimAutoCmdOpt vimOption
hi link vimAutoSet vimCommand
hi link vimCondHL vimCommand
hi link vimElseif vimCondHL
hi link vimFold Folded
hi link vimSynOption Special
hi link vimHLMod PreProc
hi link vimKeyCode vimSpecFile
hi link vimKeyword Statement
hi link vimSpecial Type
hi link vimStatement Statement
