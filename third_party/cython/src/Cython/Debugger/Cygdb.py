#!/usr/bin/env python

"""
The Cython debugger

The current directory should contain a directory named 'cython_debug', or a
path to the cython project directory should be given (the parent directory of
cython_debug).

Additional gdb args can be provided only if a path to the project directory is
given.
"""

import os
import sys
import glob
import tempfile
import textwrap
import subprocess
import optparse
import logging

logger = logging.getLogger(__name__)

def make_command_file(path_to_debug_info, prefix_code='', no_import=False):
    if not no_import:
        pattern = os.path.join(path_to_debug_info,
                               'cython_debug',
                               'cython_debug_info_*')
        debug_files = glob.glob(pattern)

        if not debug_files:
            sys.exit('%s.\nNo debug files were found in %s. Aborting.' % (
                                   usage, os.path.abspath(path_to_debug_info)))

    fd, tempfilename = tempfile.mkstemp()
    f = os.fdopen(fd, 'w')
    try:
        f.write(prefix_code)
        f.write('set breakpoint pending on\n')
        f.write("set print pretty on\n")
        f.write('python from Cython.Debugger import libcython, libpython\n')

        if no_import:
            # don't do this, this overrides file command in .gdbinit
            # f.write("file %s\n" % sys.executable)
            pass
        else:
            path = os.path.join(path_to_debug_info, "cython_debug", "interpreter")
            interpreter_file = open(path)
            try:
                interpreter = interpreter_file.read()
            finally:
                interpreter_file.close()
            f.write("file %s\n" % interpreter)
            f.write('\n'.join('cy import %s\n' % fn for fn in debug_files))
            f.write(textwrap.dedent('''\
                python
                import sys
                try:
                    gdb.lookup_type('PyModuleObject')
                except RuntimeError:
                    sys.stderr.write(
                        'Python was not compiled with debug symbols (or it was '
                        'stripped). Some functionality may not work (properly).\\n')
                end

                source .cygdbinit
            '''))
    finally:
        f.close()

    return tempfilename

usage = "Usage: cygdb [options] [PATH [-- GDB_ARGUMENTS]]"

def main(path_to_debug_info=None, gdb_argv=None, no_import=False):
    """
    Start the Cython debugger. This tells gdb to import the Cython and Python
    extensions (libcython.py and libpython.py) and it enables gdb's pending
    breakpoints.

    path_to_debug_info is the path to the Cython build directory
    gdb_argv is the list of options to gdb
    no_import tells cygdb whether it should import debug information
    """
    parser = optparse.OptionParser(usage=usage)
    parser.add_option("--gdb-executable",
        dest="gdb", default='gdb',
        help="gdb executable to use [default: gdb]")
    parser.add_option("--verbose", "-v",
        dest="verbosity", action="count", default=0,
        help="Verbose mode. Multiple -v options increase the verbosity")

    (options, args) = parser.parse_args()
    if path_to_debug_info is None:
        if len(args) > 1:
            path_to_debug_info = args[0]
        else:
            path_to_debug_info = os.curdir

    if gdb_argv is None:
        gdb_argv = args[1:]

    if path_to_debug_info == '--':
        no_import = True

    logging_level = logging.WARN
    if options.verbosity == 1:
        logging_level = logging.INFO
    if options.verbosity == 2:
        logging_level = logging.DEBUG
    logging.basicConfig(level=logging_level)

    logger.info("verbosity = %r", options.verbosity)
    logger.debug("options = %r; args = %r", options, args)
    logger.debug("Done parsing command-line options. path_to_debug_info = %r, gdb_argv = %r",
        path_to_debug_info, gdb_argv)

    tempfilename = make_command_file(path_to_debug_info, no_import=no_import)
    logger.info("Launching %s with command file: %s and gdb_argv: %s",
        options.gdb, tempfilename, gdb_argv)
    logger.debug('Command file (%s) contains: """\n%s"""', tempfilename, open(tempfilename).read())
    logger.info("Spawning %s...", options.gdb)
    p = subprocess.Popen([options.gdb, '-command', tempfilename] + gdb_argv)
    logger.info("Spawned %s (pid %d)", options.gdb, p.pid)
    while True:
        try:
            logger.debug("Waiting for gdb (pid %d) to exit...", p.pid)
            ret = p.wait()
            logger.debug("Wait for gdb (pid %d) to exit is done. Returned: %r", p.pid, ret)
        except KeyboardInterrupt:
            pass
        else:
            break
    logger.debug("Removing temp command file: %s", tempfilename)
    os.remove(tempfilename)
    logger.debug("Removed temp command file: %s", tempfilename)
