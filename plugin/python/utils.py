import subprocess
import sys
import os
import json
import vimpy

from enum import IntEnum

comment_template = """
/**
 * ${func_name}
 * @${param}:
 *
 * Returns: None
 */
"""
vsInfo = None

def process_cmd(cmd, cwd):
    """ Abstract subprocess """
    use_shell = False
    if sys.platform == "win32":
        use_shell = True

    proc = subprocess.Popen(cmd,
                            cwd=cwd,
                            shell=use_shell,
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            universal_newlines=True)
    stdout, stderr = proc.communicate()
    return stdout, stderr


def get_vs_info():
    global vsInfo

    if vsInfo:
        return vsInfo

    vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
    cmd = [vswhere, "-format", "json"]

    out, err = process_cmd(cmd, os.getcwd())
    if err:
        return None

    vsInfo = json.loads(out)
    return vsInfo


def get_vs_header_path():
    vss = get_vs_info()
    vs = None
    inc_path = None

    if len(vss) == 0:
        return None

    vs = vss[-1]

    # vs 2017
    if vs["installationVersion"].startswith("15."):
        inc_path = "%s/VC/Tools/MSVC/14.16.27023/include" % (vs["installationPath"])

    return inc_path.replace("\\", "/")


def get_system_header_path():
    incs = None

    if sys.platform == "win32":
        vinc = get_vs_header_path()
        incs = ["C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um",
                "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/ucrt"]
        if vinc:
            incs.append(vinc)

    if sys.platform == "unix":
        incs = ["/usr/include/x86_64-linux-gnu",
                "/usr/include",
                "/usr/local/include",
                "/usr/lib/gcc/x86_64-linux-gnu/9/include",
                "/usr/include/c++/9",
                "/usr/include/x86_64-linux-gnu/c++/9",
                "/usr/include/c++/9/backward"]

    return incs


def get_system_header_str():
    hds = get_system_header_path()
    return ",".join(hds).replace(" ", "\\ ")


class FileType(IntEnum):
    LANG_C      = 1
    LANG_PYTHON = 2
    LANG_CSHARP = 3

class CommentParser:
    def __init__(self):
        self.offset = 0
        self.line = None

    def func_comment(self):
        pass

    def lexer_next_c(self, reverse = False):
        if reverse:
            self.offset -= 1
        else:
            self.offset += 1

        if self.offset <= 0:
            return '\0'

        return self.line[self.offset]

    def is_id(self, c):
        return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')

    def seek(self, p):
        self.offset = p

    def seek_c(self, c):
        p = self.line[self.offset:].find(c)
        if p > -1:
            self.offset = self.offset + p

        return p

    def lexer_next(self, reverse = False):
        iden = ""

        while True:
            c = self.lexer_next_c(reverse)

            while self.is_id(c):
                iden += c
                c = self.lexer_next_c(reverse)
                continue

            if c == '\n' or c == '\0':
                break

            if c == '(':
                break

            if c == ' ':
                break

        if reverse:
            niden = ""
            for i in reversed(iden):
                niden += i

            iden = niden

        return iden

    def parse_c_proto(self):
        iden = None

        #       return,   name, [params]
        proto = [None,    None,      None]

        p = self.seek_c("(")
        if p == -1:
            return

        iden = self.lexer_next(True)
        proto[1] = iden

        iden = self.lexer_next(True)
        proto[0] = iden

        self.seek(p)
        iden = self.lexer_next()

    def get_filelang(self, filename):
        if filename.endswith(".c"):
            return FileType.LANG_C
        elif filename.endswith(".py"):
            return FileType.LANG_PYTHON
        elif filename.endswith(".cs"):
            return FileType.LANG_CSHARP

    def get_comment(self):
        lang = self.get_filelang(vimpy.vim_fullname())

        self.line = vimpy.vim_get_line()
        if lang == FileType.LANG_C:
            proto = self.parse_c_proto()

g_comment = CommentParser()
