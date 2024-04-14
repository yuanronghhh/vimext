import vim
import logging

def fullname():
    return vim.eval("expand(\"%:p\")")

def eval(s):
    return vim.eval(s)

def ctags_bin():
    return vim.eval("$vimext_home") + "/tools/ctags"

def excutable(name):
    return vim.eval('execuable("%s")' % (name))

def has(name):
    return int(vim.eval('has("%s")' % (name)))

def get_line():
    line = vim.eval("getline(\".\")")
    return line

def lines_s(s):
    lines = vim.bindeval("vimext#GetLinesEnds(\"%s\")" % (s))
    nline = ""
    for l in lines:
        nline += l.decode("utf-8") + "\n"
    nline = nline[0:-1]

    return nline

def get_content(buf):
    lines = vim.bindeval("vimext#GetContent(\"%s\", 0, -1)" % (buf))

    nline = ""
    for l in lines:
        nline += l.decode("utf-8") + "\n"
    nline = nline[0:-1]

    return nline

def search(s, flag):
    vim.eval("search(\"%s\", \"%s\")" % (s, flag))
