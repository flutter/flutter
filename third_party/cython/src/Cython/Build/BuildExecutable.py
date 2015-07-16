"""
Compile a Python script into an executable that embeds CPython and run it.
Requires CPython to be built as a shared library ('libpythonX.Y').

Basic usage:

    python cythonrun somefile.py [ARGS]
"""

DEBUG = True

import sys
import os
from distutils import sysconfig

def get_config_var(name, default=''):
    return sysconfig.get_config_var(name) or default

INCDIR = sysconfig.get_python_inc()
LIBDIR1 = get_config_var('LIBDIR')
LIBDIR2 = get_config_var('LIBPL')
PYLIB = get_config_var('LIBRARY')
PYLIB_DYN = get_config_var('LDLIBRARY')
if PYLIB_DYN == PYLIB:
    # no shared library
    PYLIB_DYN = ''
else:
    PYLIB_DYN = os.path.splitext(PYLIB_DYN[3:])[0] # 'lib(XYZ).so' -> XYZ

CC = get_config_var('CC', os.environ.get('CC', ''))
CFLAGS = get_config_var('CFLAGS') + ' ' + os.environ.get('CFLAGS', '')
LINKCC = get_config_var('LINKCC', os.environ.get('LINKCC', CC))
LINKFORSHARED = get_config_var('LINKFORSHARED')
LIBS = get_config_var('LIBS')
SYSLIBS = get_config_var('SYSLIBS')
EXE_EXT = sysconfig.get_config_var('EXE')

def _debug(msg, *args):
    if DEBUG:
        if args:
            msg = msg % args
        sys.stderr.write(msg + '\n')

def dump_config():
    _debug('INCDIR: %s', INCDIR)
    _debug('LIBDIR1: %s', LIBDIR1)
    _debug('LIBDIR2: %s', LIBDIR2)
    _debug('PYLIB: %s', PYLIB)
    _debug('PYLIB_DYN: %s', PYLIB_DYN)
    _debug('CC: %s', CC)
    _debug('CFLAGS: %s', CFLAGS)
    _debug('LINKCC: %s', LINKCC)
    _debug('LINKFORSHARED: %s', LINKFORSHARED)
    _debug('LIBS: %s', LIBS)
    _debug('SYSLIBS: %s', SYSLIBS)
    _debug('EXE_EXT: %s', EXE_EXT)

def runcmd(cmd, shell=True):
    if shell:
        cmd = ' '.join(cmd)
        _debug(cmd)
    else:
        _debug(' '.join(cmd))

    try:
        import subprocess
    except ImportError: # Python 2.3 ...
        returncode = os.system(cmd)
    else:
        returncode = subprocess.call(cmd, shell=shell)
    
    if returncode:
        sys.exit(returncode)

def clink(basename):
    runcmd([LINKCC, '-o', basename + EXE_EXT, basename+'.o', '-L'+LIBDIR1, '-L'+LIBDIR2]
           + [PYLIB_DYN and ('-l'+PYLIB_DYN) or os.path.join(LIBDIR1, PYLIB)]
           + LIBS.split() + SYSLIBS.split() + LINKFORSHARED.split())

def ccompile(basename):
    runcmd([CC, '-c', '-o', basename+'.o', basename+'.c', '-I' + INCDIR] + CFLAGS.split())

def cycompile(input_file, options=()):
    from Cython.Compiler import Version, CmdLine, Main
    options, sources = CmdLine.parse_command_line(list(options or ()) + ['--embed', input_file])
    _debug('Using Cython %s to compile %s', Version.version, input_file)
    result = Main.compile(sources, options)
    if result.num_errors > 0:
        sys.exit(1)

def exec_file(program_name, args=()):
    runcmd([os.path.abspath(program_name)] + list(args), shell=False)

def build(input_file, compiler_args=(), force=False):
    """
    Build an executable program from a Cython module.

    Returns the name of the executable file.
    """
    basename = os.path.splitext(input_file)[0]
    exe_file = basename + EXE_EXT
    if not force and os.path.abspath(exe_file) == os.path.abspath(input_file):
        raise ValueError("Input and output file names are the same, refusing to overwrite")
    if (not force and os.path.exists(exe_file) and os.path.exists(input_file)
        and os.path.getmtime(input_file) <= os.path.getmtime(exe_file)):
        _debug("File is up to date, not regenerating %s", exe_file)
        return exe_file
    cycompile(input_file, compiler_args)
    ccompile(basename)
    clink(basename)
    return exe_file

def build_and_run(args):
    """
    Build an executable program from a Cython module and runs it.

    Arguments after the module name will be passed verbatimely to the
    program.
    """
    cy_args = []
    last_arg = None
    for i, arg in enumerate(args):
        if arg.startswith('-'):
            cy_args.append(arg)
        elif last_arg in ('-X', '--directive'):
            cy_args.append(arg)
        else:
            input_file = arg
            args = args[i+1:]
            break
        last_arg = arg
    else:
        raise ValueError('no input file provided')

    program_name = build(input_file, cy_args)
    exec_file(program_name, args)

if __name__ == '__main__':
    build_and_run(sys.argv[1:])
