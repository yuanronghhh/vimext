import subprocess
import sys
import os
import json


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
    if stderr:
        return None

    return stdout

def get_vs_info():
    global vsInfo

    if vsInfo:
        return vsInfo

    vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
    cmd = [vswhere, "-format", "json"]

    out = process_cmd(cmd, os.getcwd())
    if not out:
        return None

    vsInfo = json.loads(out)
    return vsInfo

def get_vs_header_path():
    vss = get_vs_info()
    vs = None
    inc_path = None
    if len(vss) > 1:
        vs = vss[-1]

    # vs 2017
    if vs["installationVersion"].startswith("15."):
        inc_path = "%s/VC/Tools/MSVC/14.16.27023/include" % (vs["installationPath"])

    return inc_path.replace("\\", "/")

def get_system_header_path():
    incs = None

    if sys.platform == "win32":
        incs = ["C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um",
                "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/ucrt",
                get_vs_header_path()]

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
