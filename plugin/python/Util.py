import VimPy
import subprocess
import os
import json
import platform
import logging
import shutil
import tempfile
from os import path

logfile = VimPy.vimext_home() +  "/tools/log.log"
# logging.basicConfig(filename=logfile, format="%(message)s", level=logging.INFO)

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

def stat(filename):
    return os.stat(filename)

def process_cmd(cmd, cwd):
    """ Abstract subprocess """

    st = None
    if platform.system() == "Windows":
        st = subprocess.STARTUPINFO()
        st.dwFlags = subprocess.STARTF_USESHOWWINDOW
        st.wShowWindow = subprocess.SW_HIDE

    cmdstr = "%s" % (" ".join(cmd))
    rcmd = ["bash", "-c", cmdstr]

    try:
        proc = subprocess.Popen(rcmd,
                                cwd=cwd,
                                shell=False,
                                stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                startupinfo=st,
                                universal_newlines=True)

        stdout, stderr = proc.communicate()
        if stderr:
            logging.error("[err] %s" % (stderr))

        return stdout, stderr

    except Exception as err:
        logging.error("[err] %s" % (err))

    return None, "execute failed: %s" % (rcmd)


def get_vs_info():
    vscmd = "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
    if not path.exists(vscmd):
        return

    cmd = ["\"" + vscmd + "\"",
           "-format","json"]

    out, err = process_cmd(cmd, getcwd())
    if err:
        return None

    if not out:
        return None

    compilerInfo = json.loads(out)
    return compilerInfo

def get_gcc_info():
    cmd = ["gcc", "--version"]
    v = None
    out, err = process_cmd(cmd, None)
    if err:
        return None

    for line in out.split("\n"):
        v = line.split(" ")[-1]
        break

    return v

def get_compiler_ver():
    return g_util_info.version

def get_compiler_info():
    return g_util_info.compilerInfo

def get_system_header_path():
    return g_util_info.get_system_header_path()

def get_system_header_str():
    hds = g_util_info.get_system_header_path()
    if not hds:
        return ""

    return ",".join(hds).replace(" ", "\\ ")

def move_file(src, dst):
    shutil.move(src, dst)

def newtmp(mode):
    return tempfile.NamedTemporaryFile(mode, delete=False)

def json_format():
    content = VimPy.get_content("%", 0)
    if not content:
        return []

    try:
        u = json.loads(content)
        r = json.dumps(u, ensure_ascii=False, indent=2)
        return r.split("\n")
    except Exception as err:
        logging.error("[json load error] %s" % (err))
        return ""

class UtilInfo:
    def __init__(self):
        version = None
        compilerInfo = None
        self.platform = platform.system()

        if self.platform == "Windows":
            compilerInfo = get_vs_info()

            if compilerInfo:
                compilerInfo = compilerInfo[-1]
                version = compilerInfo["installationVersion"]
        elif self.platform == "Linux":
            compilerInfo = get_gcc_info()
            if compilerInfo:
                version = int(compilerInfo.split(".")[0])

        self.compilerInfo = compilerInfo
        self.version = version

    def get_system_header_path(self):
        if not self.compilerInfo:
            return []

        incs = None

        if self.platform == "Windows":
            vinc = self.get_vs_header_path()
            incs = ["C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um",
                    "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/ucrt"]
            if vinc:
                incs.append(vinc)
        elif self.platform == "Linux":
            # for termux
            p = os.getenv("PREFIX")
            if not p:
                p = "/usr"

            ver = self.version
            if not ver:
                return []

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
        else:
            return None

        return incs

    def get_vs_header_path(self):
        inc_path = None
        vs = self.compilerInfo

        # vs 2017
        if self.version.startswith("15."):
            inc_path = "%s/VC/Tools/MSVC/14.16.27023/include" % (vs["installationPath"])
        else:
            inc_path = "%s/VC/Tools/MSVC/14.29.30133/include" % (vs["installationPath"])

        return inc_path.replace("\\", "/")

g_util_info = UtilInfo()
