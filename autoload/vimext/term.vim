" Term
function s:StartTerm() abort
endfunction

function s:TermInterrupt() abort
  "call job_stop(s:job, 'int')
endfunction

function s:TermSend(cmd) abort
  "call term_sendkeys(s:term_buf, a:cmd . "\r")
endfunction
