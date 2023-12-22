import subprocess
import sys
import os
import json
import re
import platform
import logging
import vimpy

from os import path
from enum import IntEnum

# logging.basicConfig(filename="E:/tmp/log.log", format="%(message)s", level=logging.INFO)

vs = None
compilerInfo = None


def insert_patch(s, ps, ch):
    if not s:
        return

    if not ps:
        return

    nstr = ""

    for i in range(0, len(s)):
        nstr += s[i].lower()

        if i in ps:
            nstr += ch

    return nstr

def to_under_line_name(TypeName):
    uidx = []

    if not TypeName:
        return None

    if not TypeName[0].isupper():
        return None

    for i in range(0, len(TypeName)):
        if TypeName[i].isupper():
            uidx.append(i-1)

    return insert_patch(TypeName, uidx, '_')


def update_camecase_patch(s):
    if not s:
        return

    nstr = ""
    for i in range(0, len(s)):
        if s[i] == '_':
            continue

        if (i > 0 and s[i-1] == '_') or (i == 0):
            nstr += s[i].upper()
        else:
            nstr += s[i]

    return nstr

def to_camecase_name(type_name):
    uidx = []

    if not type_name:
        return None

    return update_camecase_patch(type_name)

def get_filename(file_path):
     basename = path.basename(file_path)

     return basename[0: -len(path.splitext(file_path)[1])]


def get_fullname_without_ext(file_path):
     return file_path[0: -len(path.splitext(file_path)[1])]

def get_extension(file_path):
    return path.splitext(file_path)[1]

def getcwd():
    return os.getcwd().replace("\\", "/")

def process_cmd(cmd, cwd = None, use_shell = False, silent = True, universal_newlines = False):
    """ Abstract subprocess """
    if not cwd:
        cwd = os.getcwd()

    st = None
    if platform.system() == "Windows":
        st = subprocess.STARTUPINFO()
        st.dwFlags = subprocess.STARTF_USESHOWWINDOW
        st.wShowWindow = subprocess.SW_HIDE

    if silent:
        p = subprocess.Popen(cmd,
                             cwd=cwd,
                             shell=use_shell,
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,
                             startupinfo=st,
                             universal_newlines=universal_newlines)
    else:
        p = subprocess.Popen(cmd,
                             cwd=cwd,
                             shell=use_shell,
                             startupinfo=st,
                             universal_newlines=universal_newlines)

    stdout, stderr = p.communicate()
    if stderr:
        logging.error("[err] %s" % (stderr))

    return (stdout, stderr)


def get_vs_info():
    global compilerInfo

    if compilerInfo:
        return compilerInfo

    vscmd = "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
    if not path.exists(vscmd):
        return

    cmd = [vscmd,
           "-format","json"]

    out, err = process_cmd(cmd, getcwd(), False, True, True)
    if err:
        return None

    compilerInfo = json.loads(out)
    return compilerInfo


def get_gcc_info():
    global compilerInfo

    if compilerInfo:
        return compilerInfo

    cmd = ["gcc", "--version"]

    out, err = process_cmd(cmd, getcwd(), False, True, True)
    if err:
        return None

    for line in out.split("\n"):
        v = line.split(" ")[-1]
        break

    return v


def get_gcc_ver():
    inc_path = None

    global vs
    if not vs:
        vss = get_gcc_info()
        if not vss:
            return None

        vs = vss.split(".")[0]

    return int(vs)

def get_vs_header_path():
    inc_path = None

    global vs
    if not vs:
        vss = get_vs_info()
        if not vss:
            return None

        vs = vss[-1]

    # vs 2017
    if vs["installationVersion"].startswith("15."):
        inc_path = "%s/VC/Tools/MSVC/14.16.27023/include" % (vs["installationPath"])
    else:
        inc_path = "%s/VC/Tools/MSVC/14.29.30133/include" % (vs["installationPath"])

    return inc_path.replace("\\", "/")


def get_system_header_path():
    incs = None

    if platform.system() == "Windows":
        vinc = get_vs_header_path()
        incs = ["C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um",
                "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/ucrt"]
        if vinc:
            incs.append(vinc)
    elif platform.system() == "Linux":
        ver = get_gcc_ver()
        if not ver:
            return []

        p = os.getenv("PREFIX")
        if not p:
            p = "/usr"

        incs = ["include/x86_64-linux-gnu",
                "include",
                "local/include",
                "lib/gcc/x86_64-linux-gnu/%d/include",
                "include/c++/%d",
                "include/x86_64-linux-gnu/c++/%d",
                "include/c++/%d/backward"]
        for i in range(0, len(incs)):
            inc = incs[i]
            if inc.find("%d") > -1:
                incs[i] = incs[i] % (ver)

            incs[i] = "%s/%s" % (p, incs[i])

    return incs

def get_system_header_str():
    hds = get_system_header_path()
    if not hds:
        return ""

    return ",".join(hds).replace(" ", "\\ ")
