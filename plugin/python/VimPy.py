import vim
import logging

def fullname():
    return vim.eval("expand(\"%:p\")")

def vimext_home():
    return g_vimpy_info.vimext_home

def is_unix():
    return g_vimpy_info.is_unix

def gui():
    return g_vimpy_info.gui

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

def get_content(buf, start, end = -1):
    lines = []

    if end == -1:
        lines = vim.bindeval("getbufline(\"%s\", %d, \"$\")" % (buf, start))
    else:
        lines = vim.bindeval("getbufline(\"%s\", %d, %d)" % (buf, start, end))

    nline = ""
    for l in lines:
        nline += l.decode("utf-8") + "\n"
    nline = nline[0:-1]

    return nline

def search(s, flag):
    vim.eval("search(\"%s\", \"%s\")" % (s, flag))

def taglist(regx, filename = None):
    if not filename:
        lines = vim.bindeval("taglist(\"%s\")" % (regx))
    else:
        lines = vim.bindeval("taglist(\"%s\", \"%s\")" % (regx, filename))

    return lines

class VimPyInfo:
    def __init__(self):
        self.is_unix = has("unix")
        self.gui = has("gui")
        self.vimext_home = vim.eval("$vimext_home")

g_vimpy_info = VimPyInfo()
