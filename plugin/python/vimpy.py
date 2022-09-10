import vim


def vim_fullname():
    return vim.eval("expand(\"%:p\")")

def vim_ctags_bin():
    return vim.eval("$vimext_home") + "/tools/ctags"

def vim_has(name):
    return int(vim.eval('has("%s")' % (name)))
