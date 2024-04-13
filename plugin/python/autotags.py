import logging
import os
import vimpy
import sys

from os import path
from utils import process_cmd, get_system_header_path, getcwd
from threading import Thread
import AsyncQueue


logging.basicConfig(filename="/home/greyhound/.vim/plugins/vimext/tools/log.log", format="%(message)s", level=logging.INFO)

maxsize = 100 # mb
queue = AsyncQueue.AsyncQueue()

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

            if vs.endswith(relpath) or vs == filename:
                has_match = True
                continue

            mem_write(lines, line)

        if has_match:
            fp1.seek(0)
            fp1.truncate(0)
            fp1.writelines(lines)


def ctag_update(cmd, cwd, tagfile, filename):
    if not cmd:
        return

    if filename:
        clean_tags(tagfile, filename)

    process_cmd(cmd, cwd)

class CtagsTask:
    def __init__(self, cwd, tagfile, filename):
        self.cwd = None
        self.tagfile = None
        self.filename = None

class AutoTags:
    def __init__(self):
        self.th = None
        self.tagfile = None
        self.matches = ['*.vim', '*.c', '*.h' , '*.cc', '*.cpp' , '*.hpp' , '*.py' , '*.cs' , '*.js' , 'CMakeLists.txt', '*.cmake', '*.lua', '*.java', '*.go', '*.s']
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

        self.th = Thread(target=self.ctag_thread, args=())
        self.th.setDaemon(True)
        self.th.start()

    def deinit(self):
        logging.info("deinit")

    def find_tag_recursive(self, p):
        tag = p + "/tags"

        if path.exists(tag):
            return tag

        np = path.dirname(p)
        if not path.exists(np) or np == p:
            return None

        return self.find_tag_recursive(np)

    def ctag_thread(self):
        logging.info("ctag thread start")

        while True:
            task = queue.dequeue()
            logging.info("get task2")

            cmd = self.get_ctags_cmd(task.tagfile, task.filename, task.cwd)
            ctag_update(cmd, task.cwd, task.tagfile, task.filename)

        logging.info("thread exit")

    def get_ctags_cmd(self, newtag, filename, cwd = None):
        matches = self.matches
        cmd = None

        rcmd = []
        if not cwd:
            cwd = os.getcwd()

        spec_args = ["--fields=+iaS", "--extras=+q",\
                    "--c++-kinds=+p", "--tag-relative=always", "-a", "-f", newtag]

        if not filename:
            cmd = ["find", cwd, "-type", "f"]

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

        rcmd.append(" ".join(cmd))

        return rcmd

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

        task = CtagsTask(cwd, tagfile, filename)
        queue.enqueue(task)

g_atags = AutoTags()
