  VimExtPython << EOF
import vim

rs = dir(vim)

raise Exception(rs)

vim.eval("bufadd('')")
EOF
