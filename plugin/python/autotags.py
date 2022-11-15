import logging
import os
import vimpy
import sys

from os import path
from utils import process_cmd, get_system_header_path, getcwd
from threading import Thread, Lock

logging.basicConfig(format="%(message)s", level=logging.INFO)
lock = Lock()

maxsize = 100 # mb

def os_pwrite(fp, p, bs, recp):
    fp.seek(p)
    fp.write(bs)

    end = fp.tell()
    fp.seek(recp)

    return end

def mem_write(lines, bs):
    lines.append(bs)

def clean_tags(tagfile, filename):
    pname = path.dirname(tagfile)
    relpath = filename[len(pname):].lstrip("/")
    lines = []

    with open(tagfile, "r+b") as fp1:
        has_match = False
        for line in iter(fp1.readline, b'\n'):
            if line == b'':
                break

            if line[0] == ord('!'):
                mem_write(lines, line)
                continue

            nv = line.split(b'\t')
            if len(nv) < 2:
                logging.error("may be not correct tag file")
                return False

            vs = nv[1].lstrip(b'.').replace(b'\\', b'/').decode('utf-8')

            if vs == filename:
                has_match = True
                continue

            mem_write(lines, line)

        if has_match:
            fp1.seek(0)
            fp1.truncate(0)
            fp1.writelines(lines)

class AutoTags:
    def __init__(self):
        self.tagfile = None
        self.matches = ['*.vim', '*.c', '*.h' , '*.cpp' , '*.hpp' , '*.py' , '*.cs' , '*.js' , 'CMakeLists.txt', '*.cmake', '*.lua', '*.java']
        self.tags_cmd = "ctags"
        self.sys_incs = []
        self.igns = []
        self.std_hds = ["assert.h", "ctype.h", "errno.h", "float.h", "iso646.h", \
                "limits.h", "locale.h", "math.h", "setjmp.h", "signal.h", \
                "stdarg.h", "stdbool.h", "stddef.h", "stdint.h", "stdio.h", \
                "stdlib.h", "string.h", "time.h", "uchar.h", "wchar.h", "malloc.h" \
                "wctype.h"]


        if sys.platform == "win32":
            self.tags_cmd = vimpy.vim_ctags_bin()
            self.tags_cmd = self.tags_cmd + ".exe"
            self.igns = ["__THROW", "_Check_return_wat_", "__cdecl", "_ACRTIMP", "_In_",
                    "_Check_return_", "_Success_", "_In_z_", "_Check_return_opt_",
                    "_Ret_maybenull_", "_Post_writable_byte_size_", "_CRTALLOCATOR",
                    "_CRT_JIT_INTRINSIC", "_CRTRESTRICT", "_CRT_HYBRIDPATCHABLE" "_CRT_GUARDOVERFLOW",
                    "_Inout_", "_CRT_STDIO_INLINE", "__CRTDECL", "_Printf_format_string_", "_MarkAllocaS"]
        else:
            pass

        self.sys_incs = get_system_header_path()


    def find_tag_recursive(self, p):
        tag = p + "/tags"

        if path.exists(tag):
            return tag

        np = path.dirname(p)
        if not path.exists(np) or np == p:
            return None

        return self.find_tag_recursive(np)

    def ctag_update(self, cwd, tagfile, filename):
        cmd = self.get_ctags_cmd(tagfile, filename)
        if not cmd:
            return

        lock.acquire(blocking=True)
        if filename:
            clean_tags(tagfile, filename)
        out, err = process_cmd(cmd, cwd)
        lock.release()

    def get_ctags_cmd(self, newtag, filename):
        matches = self.matches
        cmd = None

        spec_args = ["--fields=+iaS", "--extras=+q",\
                    "--c++-kinds=+p", "--tag-relative=always", "-a", "-f", newtag]

        if not filename:
            cmd = ["find", "./", "-type", "f"]

            for e in matches:
                cmd.append("-name")
                cmd.append("\"" + e + "\"")

                if e != matches[-1]:
                    cmd.append("-or")

            cmd.extend(["|", "xargs", "-d", "\"\\n\"", self.tags_cmd])
        else:
            cmd = [self.tags_cmd]

        cmd.extend(spec_args)

        if filename:
            cmd.append(filename)

        for ig in self.igns:
            cmd.append("-I")
            cmd.append("\"" + ig + "\"")


        for inc in self.sys_incs:
            for h in self.std_hds:
                if sys.platform == "win32":
                    oinc = "\"%s/%s\"" % (inc, h)
                else:
                    oinc = "%s/%s" % (inc, h)

                if not path.exists(oinc):
                    continue

                cmd.append(oinc)

        return cmd

    def regen_tags(self):
        self.gen_tags(False)

    def gen_tags(self, is_cmd = True):
        cwd = None
        tagfile = self.tagfile

        if not is_cmd:
            filename = vimpy.vim_fullname()
            if not filename:
                return

            filename = filename.replace("\\", "/")

            p = path.dirname(filename)
            if not self.tagfile or not self.tagfile.startswith(p) or not path.exists(self.tagfile):
                tagfile = self.find_tag_recursive(p)
                if not tagfile:
                    return

            st = os.stat(tagfile)
            if (st.st_size / 1024 / 1024) > maxsize:
                return

            ext = path.splitext(filename)[-1]
            for m in self.matches:
                if m.endswith(ext):
                    break
            else:
                return

            cwd = path.dirname(tagfile)
        else:
            tagfile = "tags"
            cwd = getcwd()
            filename = None

        self.tagfile = tagfile

        th = Thread(target=self.ctag_update, args=(cwd, tagfile, filename))
        th.start()

g_atags = AutoTags()
