"""
Highly experimental script that compiles the CPython standard library using Cython.

Execute the script either in the CPython 'Lib' directory or pass the
option '--current-python' to compile the standard library of the running
Python interpreter.

Pass '-j N' to get a parallel build with N processes.

Usage example::

    $ python cystdlib.py --current-python build_ext -i
"""

import os
import sys
from distutils.core import setup
from Cython.Build import cythonize
from Cython.Compiler import Options

# improve Python compatibility by allowing some broken code
Options.error_on_unknown_names = False
Options.error_on_uninitialized = False

exclude_patterns = ['**/test/**/*.py', '**/tests/**/*.py', '**/__init__.py']
broken = [
    'idlelib/MultiCall.py',
    'email/utils.py',
    'multiprocessing/reduction.py',
    'multiprocessing/util.py',
    'threading.py',      # interrupt handling
    'lib2to3/fixes/fix_sys_exc.py',
    'traceback.py',
    'types.py',
    'enum.py',
    'importlib/_bootstrap',
]

default_directives = dict(
    auto_cpdef=False,   # enable when it's safe, see long list of failures below
    binding=True,
    set_initial_path='SOURCEFILE')
default_directives['optimize.inline_defnode_calls'] = True

special_directives = [
    (['pkgutil.py',
      'decimal.py',
      'datetime.py',
      'optparse.py',
      'sndhdr.py',
      'opcode.py',
      'ntpath.py',
      'urllib/request.py',
      'plat-*/TYPES.py',
      'plat-*/IN.py',
      'tkinter/_fix.py',
      'lib2to3/refactor.py',
      'webbrowser.py',
      'shutil.py',
      'multiprocessing/forking.py',
      'xml/sax/expatreader.py',
      'xmlrpc/client.py',
      'pydoc.py',
      'xml/etree/ElementTree.py',
      'posixpath.py',
      'inspect.py',
      'ctypes/util.py',
      'urllib/parse.py',
      'warnings.py',
      'tempfile.py',
      'trace.py',
      'heapq.py',
      'pickletools.py',
      'multiprocessing/connection.py',
      'hashlib.py',
      'getopt.py',
      'os.py',
      'types.py',
     ], dict(auto_cpdef=False)),
]
del special_directives[:]  # currently unused

def build_extensions(includes='**/*.py',
                     excludes=None,
                     special_directives=special_directives,
                     language_level=sys.version_info[0],
                     parallel=None):
    if isinstance(includes, str):
        includes = [includes]
    excludes = list(excludes or exclude_patterns) + broken

    all_groups = (special_directives or []) + [(includes, {})]
    extensions = []
    for modules, directives in all_groups:
        exclude_now = excludes[:]
        for other_modules, _ in special_directives:
            if other_modules != modules:
                exclude_now.extend(other_modules)

        d = dict(default_directives)
        d.update(directives)

        extensions.extend(
            cythonize(
                modules,
                exclude=exclude_now,
                exclude_failures=True,
                language_level=language_level,
                compiler_directives=d,
                nthreads=parallel,
            ))
    return extensions


def build(extensions):
    try:
        setup(ext_modules=extensions)
        result = True
    except:
        import traceback
        print('error building extensions %s' % (
            [ext.name for ext in extensions],))
        traceback.print_exc()
        result = False
    return extensions, result


def _build(args):
    sys_args, ext = args
    sys.argv[1:] = sys_args
    return build([ext])


def parse_args():
    from optparse import OptionParser
    parser = OptionParser('%prog [options] [LIB_DIR (default: ./Lib)]')
    parser.add_option(
        '--current-python', dest='current_python', action='store_true',
        help='compile the stdlib of the running Python')
    parser.add_option(
        '-j', '--jobs', dest='parallel_jobs', metavar='N',
        type=int, default=1,
        help='run builds in N parallel jobs (default: 1)')
    parser.add_option(
        '-x', '--exclude', dest='excludes', metavar='PATTERN',
        action="append", help='exclude modules/packages matching PATTERN')
    options, args = parser.parse_args()
    if not args:
        args = ['./Lib']
    elif len(args) > 1:
        parser.error('only one argument expected, got %d' % len(args))
    return options, args


if __name__ == '__main__':
    options, args = parse_args()
    if options.current_python:
        # assume that the stdlib is where the "os" module lives
        os.chdir(os.path.dirname(os.__file__))
    else:
        os.chdir(args[0])

    pool = None
    parallel_jobs = options.parallel_jobs
    if options.parallel_jobs:
        try:
            import multiprocessing
            pool = multiprocessing.Pool(parallel_jobs)
            print("Building in %d parallel processes" % parallel_jobs)
        except (ImportError, OSError):
            print("Not building in parallel")
            parallel_jobs = 0

    extensions = build_extensions(
        parallel=parallel_jobs,
        excludes=options.excludes)
    sys_args = ['build_ext', '-i']
    if pool is not None:
        results = pool.map(_build, [(sys_args, ext) for ext in extensions])
        pool.close()
        pool.join()
        for ext, result in results:
            if not result:
                print("building extension %s failed" % (ext[0].name,))
    else:
        sys.argv[1:] = sys_args
        build(extensions)
