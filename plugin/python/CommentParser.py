import subprocess
import sys
import json
import re
import platform
import logging
import VimPy

from os import path
from enum import IntEnum

c_comment = """\
/**
 * ${func_name}:
${param}\
 *
 * Returns: void
 */\
"""

python_comment = """\
##
# ${func_name}:
${param}\
#
# Returns: None
##\
"""

csharp_comment = """\
/// <summary>
/// ${func_name}:
/// </summary>
${param}\
/// <returns></returns>\
"""

# logging.basicConfig(filename="E:/tmp/log.log", format="%(message)s", level=logging.INFO)

class FileType(IntEnum):
    LANG_C      = 1
    LANG_JS     = 2
    LANG_PYTHON = 3
    LANG_CSHARP = 4

class FunctionParam:
    def __init__(self):
        self.type = 0
        self.name = ""

class FunctionProto:
    def __init__(self):
        self.func_name = ""
        self.params = []
        self.ret = None

class CommentParser:
    def __init__(self):
        self.offset = 0
        self.line = None
        self.lang = FileType.LANG_C

    def func_comment(self):
        pass

    def lexer_next_c(self, reverse = False):
        toffset = self.offset

        if reverse:
            toffset -= 1
        else:
            toffset += 1

        if toffset < 0:
            return '\0'
        self.offset = toffset

        return self.line[self.offset]

    def is_id(self, c):
        return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c == '_')

    def c(self, p = None):
        if not p:
            p = self.offset

        return self.line[p]

    def is_c(self, c):
        return self.line[self.offset] == c

    def seek_p(self, p):
        self.offset = p

    def seek_c(self, c):
        p = self.line[self.offset:].find(c)
        return p + self.offset

    def get(self, s, e):
        return self.line[s:e]

    def seek_c_to(self, c):
        p = self.seek_c(c)
        if p > -1:
            self.offset = self.offset + p

        return p

    def lexer_next(self, reverse = False):
        iden = ""

        while True:
            c = self.lexer_next_c(reverse)

            if c == '\n' or c == '\0':
                break

            if self.is_id(c):
                iden += c
                continue

            if c == '(':
                break

            if c == ' ':
                break

        if reverse:
            iden = "".join(reversed(iden))

        return iden

    def get_right_id(self, s):
        ns = ""
        p = 0
        slen = len(s)

        for c in reversed(s):
            p += 1
            if c == ' ':
                if ns == "":
                    continue
                break

            if not self.is_id(c):
                if c != s[-1] and s[slen - p - 1] != ' ':
                    if len(ns) > 0:
                        ns += " "
                continue

            ns += c

        return "".join(reversed(ns)), p


    def parse_params(self, sp):
        params = []

        self.seek_p(sp)
        ep = self.seek_c(')')
        if ep == -1:
            return params

        values = self.get(sp + 1, ep)
        ps = values.split(",")

        for s in ps:
            r = s
            param = FunctionParam()
            equal_p = s.find("=")
            if equal_p > -1:
                r = s[:equal_p]

            ns, p = self.get_right_id(r)
            if not ns:
                continue

            if self.lang == FileType.LANG_PYTHON:
                if ns == "self":
                    continue

            param.name = ns
            param.type = re.sub(r" +", " ", s[:-p+1]).replace("\n", "")
            params.append(param)

        return params

    def parse_c_proto(self):
        proto = FunctionProto()

        p = self.seek_c_to("(")
        if p == -1:
            return

        proto.func_name = self.lexer_next(True)
        if not proto.func_name: # space
            proto.func_name = self.lexer_next(True)

        proto.params = self.parse_params(p)
        proto.ret = "None"

        return proto

    def get_filelang(self, filename):
        if filename.endswith(".c"):
            return FileType.LANG_C
        elif filename.endswith(".py"):
            return FileType.LANG_PYTHON
        elif filename.endswith(".cs"):
            return FileType.LANG_CSHARP
        elif filename.endswith(".js"):
            return FileType.LANG_JS

    def get_indent(self):
        indent = 0
        for c in self.line:
            if c != ' ' and c != '\t':
                break

            indent += 1

        return indent

    def gen_param_str(self, comment, pattern, params):
        pstr = ""
        for p in params:
            pstr += (pattern % (p.name))

        if not pstr:
            pstr = ("%s\n" % (comment))

        return pstr

    def get_comment(self):
        filename = VimPy.fullname()
        lang = self.get_filelang(filename)
        comment = None

        if lang in [FileType.LANG_C, FileType.LANG_JS, FileType.LANG_CSHARP]:
            self.line = VimPy.lines_s("{")
        elif lang == FileType.LANG_PYTHON:
            self.line = VimPy.lines_s(":")

        if not self.line:
            return

        self.lang = lang

        proto = self.parse_c_proto()
        if not proto:
            proto = FunctionProto()
            proto.func_name = ""
            proto.params = []
            proto.ret = None

        if lang == FileType.LANG_C or lang == FileType.LANG_JS:
            pstr = self.gen_param_str(" *", " * @%s:\n", proto.params)
            comment = c_comment.replace("${func_name}", proto.func_name)\
                    .replace("${param}", pstr)
        elif lang == FileType.LANG_PYTHON:
            pstr = self.gen_param_str("#", "# @%s:\n", proto.params)
            comment = python_comment.replace("${func_name}", proto.func_name)\
                    .replace("${param}", pstr)
        elif lang == FileType.LANG_CSHARP:
            pstr = self.gen_param_str("///", "/// <param name=\"%s\"></param>\n", proto.params)
            comment = csharp_comment.replace("${func_name}", proto.func_name)\
                    .replace("${param}", pstr)
        else:
            pass

        lines = comment.split("\n")
        if not proto.ret:
            lines = lines[:-2]

        indent = self.get_indent()
        for i in range(0, len(lines)):
            lines[i] = (' ' * indent) + lines[i]

        return lines

def get_comment():
    p = CommentParser()
    lines = p.get_comment()
    if not lines:
        return []

    return lines
