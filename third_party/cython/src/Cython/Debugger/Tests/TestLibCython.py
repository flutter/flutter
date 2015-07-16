
import os
import re
import sys
import shutil
import warnings
import textwrap
import unittest
import tempfile
import subprocess
#import distutils.core
#from distutils import sysconfig
from distutils import ccompiler

import runtests
import Cython.Distutils.extension
import Cython.Distutils.build_ext
from Cython.Debugger import Cygdb as cygdb

root = os.path.dirname(os.path.abspath(__file__))
codefile = os.path.join(root, 'codefile')
cfuncs_file = os.path.join(root, 'cfuncs.c')

f = open(codefile)
try:
    source_to_lineno = dict([ (line.strip(), i + 1) for i, line in enumerate(f) ])
finally:
    f.close()

# Cython.Distutils.__init__ imports build_ext from build_ext which means we
# can't access the module anymore. Get it from sys.modules instead.
build_ext = sys.modules['Cython.Distutils.build_ext']


have_gdb = None
def test_gdb():
    global have_gdb
    if have_gdb is not None:
        return have_gdb

    try:
        p = subprocess.Popen(['gdb', '-v'], stdout=subprocess.PIPE)
        have_gdb = True
    except OSError:
        # gdb was not installed
        have_gdb = False
    else:
        gdb_version = p.stdout.read().decode('ascii', 'ignore')
        p.wait()
        p.stdout.close()

    if have_gdb:
        # Based on Lib/test/test_gdb.py
        regex = "^GNU gdb [^\d]*(\d+)\.(\d+)"
        gdb_version_number = list(map(int, re.search(regex, gdb_version).groups()))

        if gdb_version_number >= [7, 2]:
            python_version_script = tempfile.NamedTemporaryFile(mode='w+')
            try:
                python_version_script.write(
                    'python import sys; print("%s %s" % sys.version_info[:2])')
                python_version_script.flush()
                p = subprocess.Popen(['gdb', '-batch', '-x', python_version_script.name],
                                     stdout=subprocess.PIPE)
                try:
                    python_version = p.stdout.read().decode('ascii')
                    p.wait()
                finally:
                    p.stdout.close()
                try:
                    python_version_number = list(map(int, python_version.split()))
                except ValueError:
                    have_gdb = False
            finally:
                python_version_script.close()

    # Be Python 3 compatible
    if (not have_gdb
        or gdb_version_number < [7, 2]
        or python_version_number < [2, 6]):
        warnings.warn(
            'Skipping gdb tests, need gdb >= 7.2 with Python >= 2.6')
        have_gdb = False

    return have_gdb


class DebuggerTestCase(unittest.TestCase):

    def setUp(self):
        """
        Run gdb and have cygdb import the debug information from the code
        defined in TestParseTreeTransforms's setUp method
        """
        if not test_gdb():
            return

        self.tempdir = tempfile.mkdtemp()
        self.destfile = os.path.join(self.tempdir, 'codefile.pyx')
        self.debug_dest = os.path.join(self.tempdir,
                                      'cython_debug',
                                      'cython_debug_info_codefile')
        self.cfuncs_destfile = os.path.join(self.tempdir, 'cfuncs')

        self.cwd = os.getcwd()
        try:
            os.chdir(self.tempdir)

            shutil.copy(codefile, self.destfile)
            shutil.copy(cfuncs_file, self.cfuncs_destfile + '.c')

            compiler = ccompiler.new_compiler()
            compiler.compile(['cfuncs.c'], debug=True, extra_postargs=['-fPIC'])

            opts = dict(
                test_directory=self.tempdir,
                module='codefile',
            )

            optimization_disabler = build_ext.Optimization()

            cython_compile_testcase = runtests.CythonCompileTestCase(
                workdir=self.tempdir,
                # we clean up everything (not only compiled files)
                cleanup_workdir=False,
                tags=runtests.parse_tags(codefile),
                **opts
            )


            new_stderr = open(os.devnull, 'w')

            stderr = sys.stderr
            sys.stderr = new_stderr

            optimization_disabler.disable_optimization()
            try:
                cython_compile_testcase.run_cython(
                    targetdir=self.tempdir,
                    incdir=None,
                    annotate=False,
                    extra_compile_options={
                        'gdb_debug':True,
                        'output_dir':self.tempdir,
                    },
                    **opts
                )

                cython_compile_testcase.run_distutils(
                    incdir=None,
                    workdir=self.tempdir,
                    extra_extension_args={'extra_objects':['cfuncs.o']},
                    **opts
                )
            finally:
                optimization_disabler.restore_state()
                sys.stderr = stderr
                new_stderr.close()

            # ext = Cython.Distutils.extension.Extension(
                # 'codefile',
                # ['codefile.pyx'],
                # cython_gdb=True,
                # extra_objects=['cfuncs.o'])
            #
            # distutils.core.setup(
                # script_args=['build_ext', '--inplace'],
                # ext_modules=[ext],
                # cmdclass=dict(build_ext=Cython.Distutils.build_ext)
            # )

        except:
            os.chdir(self.cwd)
            raise

    def tearDown(self):
        if not test_gdb():
            return
        os.chdir(self.cwd)
        shutil.rmtree(self.tempdir)


class GdbDebuggerTestCase(DebuggerTestCase):

    def setUp(self):
        if not test_gdb():
            return

        super(GdbDebuggerTestCase, self).setUp()

        prefix_code = textwrap.dedent('''\
            python

            import os
            import sys
            import traceback

            def excepthook(type, value, tb):
                traceback.print_exception(type, value, tb)
                os._exit(1)

            sys.excepthook = excepthook

            # Have tracebacks end up on sys.stderr (gdb replaces sys.stderr
            # with an object that calls gdb.write())
            sys.stderr = sys.__stderr__

            end
            ''')

        code = textwrap.dedent('''\
            python

            from Cython.Debugger.Tests import test_libcython_in_gdb
            test_libcython_in_gdb.main(version=%r)

            end
            ''' % (sys.version_info[:2],))

        self.gdb_command_file = cygdb.make_command_file(self.tempdir,
                                                        prefix_code)

        f = open(self.gdb_command_file, 'a')
        try:
            f.write(code)
        finally:
            f.close()

        args = ['gdb', '-batch', '-x', self.gdb_command_file, '-n', '--args',
                sys.executable, '-c', 'import codefile']

        paths = []
        path = os.environ.get('PYTHONPATH')
        if path:
            paths.append(path)
        paths.append(os.path.dirname(os.path.dirname(
            os.path.abspath(Cython.__file__))))
        env = dict(os.environ, PYTHONPATH=os.pathsep.join(paths))

        self.p = subprocess.Popen(
            args,
            stdout=open(os.devnull, 'w'),
            stderr=subprocess.PIPE,
            env=env)

    def tearDown(self):
        if not test_gdb():
            return

        try:
            super(GdbDebuggerTestCase, self).tearDown()
            if self.p:
                try: self.p.stdout.close()
                except: pass
                try: self.p.stderr.close()
                except: pass
                self.p.wait()
        finally:
            os.remove(self.gdb_command_file)


class TestAll(GdbDebuggerTestCase):

    def test_all(self):
        if not test_gdb():
            return

        out, err = self.p.communicate()
        err = err.decode('UTF-8')

        exit_status = self.p.returncode

        if exit_status == 1:
            sys.stderr.write(err)
        elif exit_status >= 2:
            border = u'*' * 30
            start  = u'%s   v INSIDE GDB v   %s' % (border, border)
            end    = u'%s   ^ INSIDE GDB ^   %s' % (border, border)
            errmsg = u'\n%s\n%s%s' % (start, err, end)

            sys.stderr.write(errmsg)


if __name__ == '__main__':
    unittest.main()
