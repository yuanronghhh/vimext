# import vim


def vim_fullname():
    return "E:/Codes/REPOSITORY/vim/plugins/vimext/plugin/python/vimpy.c"
    return vim.eval("expand(\"%:p\")")

def vim_ctags_bin():
    return vim.eval("$vimext_home") + "/tools/ctags"

def vim_has(name):
    return int(vim.eval('has("%s")' % (name)))

def vim_get_line():
    return "void stati_get_func(void* a,void *b);"
    line = vim.eval("getline(\".\")")
    return line
