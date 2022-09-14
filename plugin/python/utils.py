import subprocess
import sys


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
                            stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    return stdout

def get_vs_info():
    vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
    cmd = ("\"%s\" -format json" % (vswhere))

    out, err = process(cmd, True)
    if err:
        return None

    return json.loads(out)

def get_vs_header_path():
    vs = get_vs_info()
    inc_path = "%s/VC/Tools/MSVC/14.16.27023/include" % (vs["installationPath"])
    return inc_path
