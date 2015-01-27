# Copyright (C) 2014 Google Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

import fnmatch
import os
import shutil
import sys
import tempfile

from webkitpy.common.checkout.scm.detection import detect_scm_system
from webkitpy.common.system import executive
from webkitpy.common.system.executive import ScriptError

# Add Source path to PYTHONPATH to support function calls to bindings/scripts
# for compute_dependencies and idl_compiler
module_path = os.path.dirname(__file__)
source_path = os.path.normpath(os.path.join(module_path, os.pardir,
                                            os.pardir, os.pardir, os.pardir,
                                            'Source'))
sys.path.append(source_path)

from bindings.scripts.compute_interfaces_info import compute_interfaces_info, interfaces_info
from bindings.scripts.idl_compiler import IdlCompilerV8


PASS_MESSAGE = 'All tests PASS!'
FAIL_MESSAGE = """Some tests FAIL!
To update the reference files, execute:
    run-bindings-tests --reset-results

If the failures are not due to your changes, test results may be out of sync;
please rebaseline them in a separate CL, after checking that tests fail in ToT.
In CL, please set:
NOTRY=true
TBR=(someone in Source/bindings/OWNERS or WATCHLISTS:bindings)
"""

DEPENDENCY_IDL_FILES = set([
    'SupportTestPartialInterface.idl',
    'TestImplements.idl',
    'TestImplements2.idl',
    'TestImplements3.idl',
    'TestPartialInterface.idl',
    'TestPartialInterfacePython.idl',
    'TestPartialInterfacePython2.idl',
])


EXTENDED_ATTRIBUTES_FILE = 'bindings/IDLExtendedAttributes.txt'

all_input_directory = '.'  # Relative to Source/
test_input_directory = os.path.join('bindings', 'tests', 'idls')
reference_directory = os.path.join('bindings', 'tests', 'results')


class ScopedTempFileProvider(object):
    def __init__(self):
        self.file_handles = []
        self.file_paths = []
        self.dir_paths = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        for file_handle in self.file_handles:
            os.close(file_handle)
        for file_path in self.file_paths:
            os.remove(file_path)
        for dir_path in self.dir_paths:
            # Temporary directories are used as output directories, so they
            # contains unknown files (they aren't empty), hence use rmtree
            shutil.rmtree(dir_path)

    def new_temp_file(self):
        file_handle, file_path = tempfile.mkstemp()
        self.file_handles.append(file_handle)
        self.file_paths.append(file_path)
        return file_handle, file_path

    def new_temp_dir(self):
        dir_path = tempfile.mkdtemp()
        self.dir_paths.append(dir_path)
        return dir_path


class DartTests(object):
    def __init__(self, reset_results, verbose, provider):
        self.reset_results = reset_results
        self.verbose = verbose
        self.executive = executive.Executive()
        self.provider = provider
        self.idl_compiler = None
        _, self.interfaces_info_filename = provider.new_temp_file()
        # Generate output into the reference directory if resetting results, or
        # a temp directory if not.
        if reset_results:
            self.output_directory = reference_directory
        else:
            self.output_directory = provider.new_temp_dir()

    def run_command(self, cmd):
        output = self.executive.run_command(cmd)
        if output:
            print output

    def generate_from_idl(self, idl_file):
        try:
            idl_file_fullpath = os.path.realpath(idl_file)
            self.idl_compiler.compile_file(idl_file_fullpath)
        except ScriptError, e:
            print 'ERROR: idl_compiler.py: ' + os.path.basename(idl_file)
            print e.output
            return e.exit_code

        return 0

    def generate_interface_dependencies(self):
        def idl_paths(directory):
            return [os.path.join(directory, input_file)
                    for input_file in os.listdir(directory)
                    if input_file.endswith('.idl')]

        def idl_paths_recursive(directory):
            idl_paths = []
            for dirpath, _, files in os.walk(directory):
                idl_paths.extend(os.path.join(dirpath, filename)
                                 for filename in fnmatch.filter(files, '*.idl'))
            return idl_paths

        def write_list_file(idl_paths):
            list_file, list_filename = self.provider.new_temp_file()
            list_contents = ''.join(idl_path + '\n'
                                    for idl_path in idl_paths)
            os.write(list_file, list_contents)
            return list_filename

        # We compute interfaces info for *all* IDL files, not just test IDL
        # files, as code generator output depends on inheritance (both ancestor
        # chain and inherited extended attributes), and some real interfaces
        # are special-cased, such as Node.
        #
        # For example, when testing the behavior of interfaces that inherit
        # from Node, we also need to know that these inherit from EventTarget,
        # since this is also special-cased and Node inherits from EventTarget,
        # but this inheritance information requires computing dependencies for
        # the real Node.idl file.
        try:
            compute_interfaces_info(idl_paths_recursive(all_input_directory))

        except ScriptError, e:
            print 'ERROR: compute_interfaces_info.py'
            print e.output
            return e.exit_code

        return 0

    def delete_cache_files(self):
        # FIXME: Instead of deleting cache files, don't generate them.
        cache_files = [os.path.join(self.output_directory, output_file)
                       for output_file in os.listdir(self.output_directory)
                       if (output_file in ('lextab.py',  # PLY lex
                                           'lextab.pyc',
                                           'parsetab.pickle') or  # PLY yacc
                               output_file.endswith('.cache'))]  # Jinja
        for cache_file in cache_files:
            os.remove(cache_file)

    def identical_file(self, reference_filename, output_filename):
        reference_basename = os.path.basename(reference_filename)
        cmd = ['diff',
               '-u',
               '-N',
               reference_filename,
               output_filename]
        try:
            self.run_command(cmd)
        except ScriptError, e:
            # run_command throws an exception on diff (b/c non-zero exit code)
            print 'FAIL: %s' % reference_basename
            print e.output
            return False

        if self.verbose:
            print 'PASS: %s' % reference_basename
        return True

    def identical_output_files(self):
        file_pairs = [(os.path.join(reference_directory, output_file),
                       os.path.join(self.output_directory, output_file))
                      for output_file in os.listdir(self.output_directory)]
        return all([self.identical_file(reference_filename, output_filename)
                    for (reference_filename, output_filename) in file_pairs])

    def no_excess_files(self):
        generated_files = set(os.listdir(self.output_directory))
        generated_files.add('.svn')  # Subversion working copy directory
        excess_files = [output_file
                        for output_file in os.listdir(reference_directory)
                        if output_file not in generated_files]
        if excess_files:
            print ('Excess reference files! '
                  '(probably cruft from renaming or deleting):\n' +
                  '\n'.join(excess_files))
            return False
        return True

    def run_tests(self):
        # Generate output, immediately dying on failure
        if self.generate_interface_dependencies():
            return False

        self.idl_compiler = IdlCompilerV8(self.output_directory,
                                          EXTENDED_ATTRIBUTES_FILE,
                                          interfaces_info=interfaces_info,
                                          only_if_changed=True)

        for input_filename in os.listdir(test_input_directory):
            if not input_filename.endswith('.idl'):
                continue
            if input_filename in DEPENDENCY_IDL_FILES:
                # Dependencies aren't built (they are used by the dependent)
                if self.verbose:
                    print 'DEPENDENCY: %s' % input_filename
                continue

            idl_path = os.path.join(test_input_directory, input_filename)
            if self.generate_from_idl(idl_path):
                return False
            if self.reset_results and self.verbose:
                print 'Reset results: %s' % input_filename

        self.delete_cache_files()

        # Detect all changes
        passed = self.identical_output_files()
        passed &= self.no_excess_files()
        return passed

    def main(self):
        current_scm = detect_scm_system(os.curdir)
        os.chdir(os.path.join(current_scm.checkout_root, 'Source'))

        all_tests_passed = self.run_tests()
        if all_tests_passed:
            if self.verbose:
                print
                print PASS_MESSAGE
            return 0
        print
        print FAIL_MESSAGE
        return -1


def run_dart_tests(reset_results, verbose):
    with ScopedTempFileProvider() as provider:
        return DartTests(reset_results, verbose, provider).main()
