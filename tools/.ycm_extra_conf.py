import platform
import os.path as p
import subprocess
import ycm_core
import os

from distutils.sysconfig import get_python_inc
from pathlib import Path
from os import path


Deps = set()
oldflags = [
    '-Wall',
    '-Wextra',
    '-Werror',
    '-Wno-long-long',
    '-Wno-variadic-macros',
    '-fexceptions',
    '-x',
    'c'
    ]

SOURCE_EXTENSIONS = [ '.cpp', '.cxx', '.cc', '.c', '.m', '.mm' ]
DIR_OF_THIS_SCRIPT = p.abspath( p.dirname( __file__ ) )
HEADER_EXTENSIONS = [ '.h', '.hxx', '.hpp', '.hh' ]

def GetDataBase():
    compilation_database_folder = Path(DIR_OF_THIS_SCRIPT + "/build")

    database = None
    if compilation_database_folder.joinpath("compile_commands.json").exists():
        database = ycm_core.CompilationDatabase( compilation_database_folder.as_posix() )

    return database

def IsHeaderFile( filename ):
  extension = p.splitext( filename )[ 1 ]
  return extension in HEADER_EXTENSIONS

def FindCorrespondingSourceFile( filename ):
  if IsHeaderFile( filename ):
    basename = p.splitext( filename )[ 0 ]
    for extension in SOURCE_EXTENSIONS:
      replacement_file = basename + extension
      if p.exists( replacement_file ):
        return replacement_file

  return filename

def debug(info):
    abspath = Path(DIR_OF_THIS_SCRIPT).joinpath("ycm.log")

    with open(abspath, "a") as f:
      f.write(str(info) + "\n")

def GetDependenciesInc(deps):
  libdir = Path(DIR_OF_THIS_SCRIPT).parent.joinpath("lib/win64_vc14")
  for h in addition_include:
    inc = libdir.joinpath(h)
    deps.add("-I" + inc.as_posix())


def list_dir(dir: str):
    try:
        ls = os.listdir(dir)
        return ls
    except PermissionError as err:
        return []

def add_list_dir(layer: list, wk :str):
    for dn in list_dir(wk):
        fullpath = "%s/%s" % (wk, dn)

        if not path.isdir(fullpath):
            continue

        layer.append(fullpath)


def GetBFSHeaderDir(wk, deps:set, maxlevel = 5):
    level = 0
    leveldir = []
    olddir = [wk]

    deps.add("-I%s" % wk)
    while olddir and level < maxlevel:
        level += 1

        for o in olddir:
            add_list_dir(leveldir, o)
        del olddir

        for dn in leveldir:
            for fn in list_dir(dn):
                fullfn = "%s/%s" % (dn, fn)

                if not path.isfile(fullfn):
                    continue

                if fn.endswith(".h"):
                    deps.add("-I%s" % dn)

        olddir = leveldir
        leveldir = []

def GetRecursiveHeaderDir(bdir, deps, level = 2):
    if not p.exists(bdir):
        return

    for dp, dns, fns in os.walk(bdir):
        for f in fns:
            if f.endswith(".h"):
                deps.add("-I" + Path(dp).joinpath(f).parent.as_posix())


def PathToPythonUsedDuringBuild():
  try:
    filepath = p.join( DIR_OF_THIS_SCRIPT, 'PYTHON_USED_DURING_BUILDING' )

    with open( filepath ) as f:
      return f.read().strip()

  except ( IOError, OSError ):
    return None

def Settings( **kwargs ):
  language = kwargs[ 'language' ]
  flags = []

  if language == 'cfamily':
    filename = FindCorrespondingSourceFile(kwargs[ 'filename' ])

    cwd = os.getcwd()
    hmpath = path.expanduser("~")
    flags.extend(oldflags)

    if filename.startswith(cwd) and filename != hmpath:
        GetBFSHeaderDir(cwd, Deps, 3)
    else:
        GetBFSHeaderDir(path.dirname(filename), Deps, 3)
    flags.extend(Deps)

    return {
        'flags': flags,
        'include_paths_relative_to_dir': DIR_OF_THIS_SCRIPT,
        'override_filename': filename,
        "do_cache": True
    }

  if language == 'python':
    return {
        'interpreter_path': PathToPythonUsedDuringBuild()
        }

  return {}
