" mysql:0 rs_win_len:2 --database=test_db --auto-rehash

"
finish

let s:config = [
      \'mysql -h localhost -uroot -proot'
      \]
let s:rs_wins = []

"select 1;
"select * from accounts limit 10;
"show tables;

function! s:showResults()
  let edit_wm = {
        \"w_nr": bufwinnr('%'),
        \"b_nr": bufnr('%')
        \}
  let rsfile = vimext##tmpfile#getTmpFile()

  if s:rs_win  < 2
    exec 'silent! botright sview +setlocal\ noswapfile\ autoread '.rsfile
    let s:result_buf_nr = bufnr('%')

    call vimext##debug#echomsg('n wm', wm)
    call vimext##debug#echomsg('tmp_files', vimext##tmpfile#tmpFiles())
  else
    let r_wm = vimext##wmanager#getNextResult()
    call vimext##wmanager#switchWm(r_wm)
    echo '-------------------------------'
    execute 'edit '.rsfile
  endif

  set readonly
  exec bufwinnr()
endfunction

function! s:executeCmd(conn, query)
  let tmp = ''

  if (vimext##wmanager#getRsWmLen() + 1) < s:rs_win_len
    let tmp = vimext##tmpfile#newTmpFile()
  else
    let tmp = vimext##tmpfile#getNextFile()
  endif

  let cmdstring = '!'.a:conn."'".a:query."'".' > '.tmp.' 2>&1'
  call vimext##debug#echomsg('cmdstring', cmdstring)
  silent execute(cmdstring)
  call s:showResults()
endfunction

function! s:get_visual_selection()
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)

  if len(lines) == 0
    return ''
  endif

  let lines[-1] = lines[-1][:column_end - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "")
endfunction

function! s:getConnConfig()
  let line = getline(1)
  let match_params = matchstr(line, '--[^$]*')
  let match_fmt = matchstr(line, '--notable')
  let match_config = matchstr(line, '\(mysql:\)\@<=\(\S*\)')
  let conf_str = ''
  let rs_win_len_str = matchstr(getline(1), '\(rs_win_len:\)\@<=\(\S*\)')

  if !empty(rs_win_len_str)
    let s:rs_win_len = str2nr(rs_win_len_str, 10)
  else
    let s:rs_win_len = 1
  endif

  if empty(match_fmt)
    let match_fmt = '--table'
  else
    let match_fmt = ''
  endif

  if empty(match_config)
     let match_config = get(s:config, 0)
  else
    let match_config = get(s:config, str2nr(match_config, 10))
  endif

  return match_config.' '.match_fmt.' '.match_params.' -e '
endfunction

function! s:runQuery()
  let query = s:get_visual_selection()
  let conn_config = s:getConnConfig()
  call s:executeCmd(conn_config, query)
endfunction

"vnoremap <buffer> <enter> :vimext#ExecuteSql<cr>
"command! -range=% vimext#ExecuteSql call s:runQuery()
au BufNewFile,BufRead *.vue set filetype=html
