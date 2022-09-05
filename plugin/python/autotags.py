import vim
import logging
import subprocess
import array
import os

from itertools import takewhile, repeat
from os import path, chdir
from threading import Thread, Lock

logging.basicConfig(format="%(message)s", level=logging.INFO)
lock = Lock()


def do_cmd(cmd, cwd):
    """ Abstract subprocess """
    proc = subprocess.Popen(cmd,
                            cwd=cwd,
                            shell=True,
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            universal_newlines=True)
    stdout = proc.communicate()[0]
    return stdout.split("\n")


def clean_tags(tagfile, newtag, filename):
    pname = path.dirname(tagfile)
    relpath = filename[len(pname):]

    with open(tagfile, "rb") as fp1:
        with open(newtag, "wb") as fp2:
            for line in iter(fp1.readline, b''):
                if line[0] == ord('!'):
                    fp2.write(line)
                    continue

                nv = line.decode("utf-8").split('\t')
                if len(nv) < 2:
                    # may be not correct tag file
                    return False

                vs = nv[1].lstrip('.').replace("\\", "/")
                if vs == relpath or vs == filename:
                    continue

                fp2.write(line)


class AutoTags:
    def __init__(self):
        self.tagfile = None
        self.extensions = ['*.c', '*.h' , '*.cpp' , '*.hpp' , '*.py' , '*.cs' , '*.js' , 'CMakeLists.txt', '*.cmake', '*.lua', '*.java']

    def get_ctags_cmd(self, newtag, filename):
        tags_cmd = vim.eval("$vimext_home") + "/tools/ctags"
        extensions = self.extensions

        if vim.eval('has("win32")'):
            tags_cmd = tags_cmd + ".exe"

        if not filename:
            cmd = ["find", "./", "-type", "f"]

            for e in self.extensions:
                cmd.append("-name")
                cmd.append(e)

                if e != extensions[-1]:
                    cmd.append("-or")

            cmd.extend(["|", "xargs", "-d", "\'\\n\'", tags_cmd, "-a"])
        else:
            cmd = [tags_cmd, "-a", "-f", newtag, filename]

        return cmd

    def find_tag_recursive(self, p):
        tag = path.join(p, "tags")

        if path.exists(tag):
            return tag

        np = path.dirname(p)
        if not path.exists(np) or np == p:
            return None

        return self.find_tag_recursive(np)

    def ctag_update(self, tagfile, filename):
        tagdir = path.dirname(tagfile)
        newtag = tagfile + ".safe"

        cmd = self.get_ctags_cmd(newtag, filename)
        if not cmd:
            return

        lock.acquire(blocking=True)

        clean_tags(tagfile, newtag, filename)
        do_cmd(cmd, tagdir)
        os.unlink(tagfile)
        os.rename(newtag, tagfile)

        lock.release()

    def rebuild(self):
        filename = vim.eval("expand(\"%:p\")")
        if not filename:
            return
        filename = filename.replace("\\", "/")

        p = path.dirname(filename)
        tagfile = None

        if not self.tagfile or not self.tagfile.startswith(p):
            tagfile = self.find_tag_recursive(p)
            if not tagfile:
                return
        self.tagfile = tagfile

        th = Thread(target=self.ctag_update, args=(tagfile, filename))
        th.daemon = True
        th.start()

g_atags = AutoTags()
