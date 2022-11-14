import vim


def vim_fullname():
    return vim.eval("expand(\"%:p\")")

def vim_ctags_bin():
    return vim.eval("$vimext_home") + "/tools/ctags"

def vim_has(name):
    return int(vim.eval('has("%s")' % (name)))

def vim_get_line():
    line = vim.eval("getline(\".\")")
    return line

def vim_lines_s(s):
    lines = vim.bindeval("vimext#GetLinesEnds(\"%s\")" % (s))
    nline = ""
    for l in lines:
        nline += l.decode("utf-8")

    return nline

def vim_search(s, flag):
    vim.eval("search(\"%s\", \"%s\")" % (s, flag))

def vim_msg(msg):
    print(msg)
