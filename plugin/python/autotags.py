import logging
import os
import vimpy
import sys

from os import path
from utils import process_cmd
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

def binsearch_tag(fp, filename):
    pass

def clean_tags(tagfile, filename):
    pname = path.dirname(tagfile)
    relpath = filename[len(pname):].lstrip("/")
    lines = []

    with open(tagfile, "r+b") as fp1:
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
                continue

            mem_write(lines, line)

        fp1.seek(0)
        fp1.truncate(0)
        fp1.writelines(lines)

class AutoTags:
    def __init__(self):
        self.tagfile = None
        self.matches = ['*.vim', '*.c', '*.h' , '*.cpp' , '*.hpp' , '*.py' , '*.cs' , '*.js' , 'CMakeLists.txt', '*.cmake', '*.lua', '*.java']

    def find_tag_recursive(self, p):
        tag = p + "/tags"

        if path.exists(tag):
            return tag

        np = path.dirname(p)
        if not path.exists(np) or np == p:
            return None

        return self.find_tag_recursive(np)

    def ctag_update(self, tagfile, filename):
        tagdir = path.dirname(tagfile)

        cmd = self.get_ctags_cmd(tagfile, filename)
        if not cmd:
            return

        lock.acquire(blocking=True)
        clean_tags(tagfile, filename)
        process_cmd(cmd, tagdir)
        lock.release()

    def get_ctags_cmd(self, newtag, filename):
        tags_cmd = vimpy.vim_ctags_bin()
        matches = self.matches
        if vimpy.vim_has("win32"):
            tags_cmd = tags_cmd + ".exe"

        if not filename:
            cmd = ["find", "./", "-type", "f"]

            for e in matches:
                cmd.append("-name")
                cmd.append("'" + e + "'")

                if e != matches[-1]:
                    cmd.append("-or")

            cmd.extend(["|", "xargs", "-d", "\'\\n\'", tags_cmd, "-a"])
        else:
            cmd = [tags_cmd,"--tag-relative=always", "-a", "-f", newtag, filename]

        return cmd

    def rebuild(self):
        filename = vimpy.vim_fullname()
        if not filename:
            return

        filename = filename.replace("\\", "/")

        p = path.dirname(filename)
        tagfile = self.tagfile

        if not self.tagfile or not self.tagfile.startswith(p):
            tagfile = self.find_tag_recursive(p)
            if not tagfile:
                return
        self.tagfile = tagfile

        st = os.stat(tagfile)
        if (st.st_size / 1024 / 1024) > maxsize:
            return

        ext = path.splitext(filename)[-1]
        for m in self.matches:
            if m.endswith(ext):
                break
        else:
            return

        th = Thread(target=self.ctag_update, args=(tagfile, filename))
        th.daemon = True
        th.start()

g_atags = AutoTags()
