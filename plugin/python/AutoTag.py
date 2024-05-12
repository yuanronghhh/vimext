import Util
import VimPy
import AsyncQueue
import logging
import sys

from os import path
from threading import Thread, Lock

maxsize = 100 # mb

def clean_tags(tagfile, filename):
    pname = path.dirname(tagfile)
    relpath = filename[len(pname):].lstrip("/")
    lines = []

    tfp = Util.newtmp("w+b")
    fp = open(tagfile, "r+b")

    has_match = False
    for line in iter(fp.readline, b'\n'):
        if line == b'':
            break

        if line[0] == ord('!'):
            tfp.write(line)
            continue

        nv = line.split(b'\t')
        if len(nv) < 2:
            logging.error("may be not correct tag file")
            return False

        vs = nv[1].lstrip(b'.').replace(b'\\', b'/').decode('utf-8')

        if vs.endswith(relpath) or vs == filename:
            has_match = True
            continue

        tfp.write(line)

    fp.close()
    tfp.close()

    if has_match:
        Util.move_file(tfp.name, tagfile)

class CtagsTask:
    def __init__(self, cwd, tagfile, filename):
        self.cwd = cwd
        self.tagfile = tagfile
        self.filename = filename

class AutoTag:
    def __init__(self):
        self.th = None
        self.tagfile = None
        self.matches = ['*.vim',
                        '*.c', 
                        '*.h' , 
                        '*.cc', 
                        '*.cpp' , 
                        '*.hpp' , 
                        '*.py' , 
                        '*.cs' , 
                        '*.js' , 
                        'CMakeLists.txt', 
                        '*.cmake', 
                        '*.lua', 
                        '*.java', 
                        '*.go', 
                        '*.s', 
                        '*.rs']
        self.tags_cmd = "ctags"
        self.sys_incs = []
        self.igns = []

        # TODO: threading.Condition can not wakeup
        self.is_unix_gui = VimPy.is_unix() and VimPy.gui()
        self.std_hds = ["assert.h", "ctype.h", "errno.h", "float.h", "iso646.h", \
                "limits.h", "locale.h", "math.h", "setjmp.h", "signal.h", \
                "stdarg.h", "stdbool.h", "stddef.h", "stdint.h", "stdio.h", \
                "stdlib.h", "string.h", "time.h", "uchar.h", "wchar.h", "malloc.h" \
                "wctype.h"]

        self.lock = Lock()
        if not self.is_unix_gui:
            self.queue = AsyncQueue.AsyncQueue()

        if sys.platform == "win32":
            self.tags_cmd =  VimPy.vimext_home() + "/tools/ctags"
            self.tags_cmd = self.tags_cmd + ".exe"
            self.igns = ["__THROW", "_Check_return_wat_", "__cdecl", "_ACRTIMP", "_In_",
                    "_Check_return_", "_Success_", "_In_z_", "_Check_return_opt_",
                    "_Ret_maybenull_", "_Post_writable_byte_size_", "_CRTALLOCATOR",
                    "_CRT_JIT_INTRINSIC", "_CRTRESTRICT", "_CRT_HYBRIDPATCHABLE" "_CRT_GUARDOVERFLOW",
                    "_Inout_", "_CRT_STDIO_INLINE", "__CRTDECL", "_Printf_format_string_", "_MarkAllocaS"]
        else:
            pass

        self.sys_incs = Util.get_system_header_path()
        self.gen_lock = False

        if not self.is_unix_gui:
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

    def ctag_update(self, cmd, cwd, tagfile, filename):
        self.lock.acquire()

        if not cmd:
            return

        if filename:
            clean_tags(tagfile, filename)

        Util.process_cmd(cmd, cwd)

        self.lock.release()

    def ctag_thread(self):
        while True:
            task = self.queue.dequeue()
            if task is None:
                break

            cmd = self.get_ctags_cmd(task.tagfile, task.filename, task.cwd)
            self.ctag_update(cmd, task.cwd, task.tagfile, task.filename)
            self.queue.task_done()

    def new_thread_update(self, task):
        cmd = self.get_ctags_cmd(task.tagfile, task.filename, task.cwd)
        th = Thread(target=self.ctag_update, args=(cmd, task.cwd, task.tagfile, task.filename))
        th.setDaemon(True)
        th.start()

    def get_ctags_cmd(self, newtag, filename, cwd = None):
        matches = self.matches
        cmd = None

        rcmd = []
        if not cwd:
            cwd = Util.getcwd()

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
            filename = VimPy.fullname()
            if not filename:
                return

            filename = filename.replace("\\", "/")

            p = path.dirname(filename)
            if not self.tagfile or not self.tagfile.startswith(p) or not path.exists(self.tagfile):
                tagfile = self.find_tag_recursive(p)
                if not tagfile:
                    return

            st = Util.stat(tagfile)
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
            cwd = Util.getcwd()
            filename = None

        self.tagfile = tagfile

        task = CtagsTask(cwd, tagfile, filename)

        if self.is_unix_gui:
            self.new_thread_update(task)
        else:
            self.queue.enqueue(task)

g_atag = AutoTag()
