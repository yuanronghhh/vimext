let s:rs_wins = []
let s:cur_idx = -1


function! vimext#wmanager#getRsWindows() abort
  return s:rs_wins
endfunction

function! vimext#wmanager#getNextResult()
  if (s:cur_idx + 1) >= len(s:rs_wins)
    let s:cur_idx = 0

    call vimext#debug#echomsg('back1', s:cur_idx)
    return s:rs_wins[s:cur_idx]
  endif

  let s:cur_idx += 1
  call vimext#debug#echomsg('back2', s:cur_idx)
  return s:rs_wins[s:cur_idx]
endfunction

function! vimext#wmanager#switchWm(wm) abort
  let n_wn = bufwinnr(a:wm["b_nr"])
  if n_wn == -1
    return -1
  endif

  execute n_wn."wincmd w"
endfunction

function! vimext#wmanager#currentWm() abort
  let wm = {
        \"w_nr": bufwinnr('%'),
        \"b_nr": bufnr('%')
        \}
  return wm
endfunction

function! vimext#wmanager#addRsWm(wm) abort
  call add(s:rs_wins, a:wm)
endfunction

function! vimext#wmanager#getRsWmLen() abort
  return len(s:rs_wins)
endfunction
