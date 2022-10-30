import platform
import os.path as p
import subprocess
import ycm_core
import os
import logging

from distutils.sysconfig import get_python_inc
from pathlib import Path

logging.basicConfig(filename="/home/greyhound/Public/n.txt",
                    format="%(message)s", level=logging.DEBUG)

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

def GetRecursiveHeaderDir(bdir, deps):
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

    GetRecursiveHeaderDir(os.getcwd(), Deps)
    flags.extend(oldflags)
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
