#!/usr/bin/python
# Copyright (C) 2010 Google Inc.  All rights reserved.
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

import traceback

import fnmatch
from optparse import OptionParser
import os
import shutil
import sys
import tempfile

import compute_interfaces_info_individual
from compute_interfaces_info_individual import compute_info_individual, info_individual
import compute_interfaces_info_overall
from compute_interfaces_info_overall import compute_interfaces_info_overall, interfaces_info
from compiler import IdlCompilerDart

# TODO(terry): Temporary solution list of IDLs to parse and IDL as dependencies.
from idl_files import full_path_core_idl_files, full_path_core_dependency_idl_files, full_path_modules_idl_files, full_path_modules_dependency_idl_files

#from dart_tests import run_dart_tests


EXTENDED_ATTRIBUTES_FILE = 'bindings/IDLExtendedAttributes.txt'

idl_compiler = None


def parse_options():
    parser = OptionParser()

    parser.add_option("--output-directory",
                      action="store",
                      type="string",
                      dest="output_directory",
                      help="Generate output to a known directory")
    parser.add_option("-v", "--verbose",
                      action="store_true",
                      dest="verbose",
                      default=False,
                      help="Show all information messages")
    parser.add_option("-k", "--keep",
                      action="store_true",
                      dest="keep",
                      default=False,
                      help="Don't delete the temporary directory on exit")
    parser.add_option("--compute-idls", type='int', help="Compile IDLs interfaces and dependencies (GYP)")
    parser.add_option('--globals-only', type='int', help="Generate the globals")

    options, args = parser.parse_args()

    options.compute_idls = bool(options.compute_idls)
    options.globals_only = bool(options.globals_only)

    return options


class ScopedTempFileProvider(object):
    def __init__(self, keep=False):
        self.keep = keep
        self.dir_paths = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if not self.keep:
            for dir_path in self.dir_paths:
                # Temporary directories are used as output directories, so they
                # contains unknown files (they aren't empty), hence use rmtree
                shutil.rmtree(dir_path)

    def new_temp_dir(self):
        dir_path = tempfile.mkdtemp()
        self.dir_paths.append(dir_path)
        return dir_path


class DirectoryProvider(object):
    def __init__(self, path=""):
        self.dir_path = path

    def __enter__(self):
        return self

    def new_temp_dir(self):
        return self.dir_path


def idl_paths_recursive(directory):
    idl_paths = []
    for dirpath, _, files in os.walk(directory):
        idl_paths.extend(os.path.join(dirpath, filename)
                         for filename in fnmatch.filter(files, '*.idl'))
    return idl_paths


class Build():
    def __init__(self, provider):
        self.output_directory = provider.new_temp_dir()

        attrib_file = os.path.join('Source', EXTENDED_ATTRIBUTES_FILE)
        # Create compiler.
        self.idl_compiler = IdlCompilerDart(self.output_directory,
                                            attrib_file,
                                            interfaces_info=interfaces_info,
                                            only_if_changed=True)

    def format_exception(self, e):
        exception_list = traceback.format_stack()
        exception_list = exception_list[:-2]
        exception_list.extend(traceback.format_tb(sys.exc_info()[2]))
        exception_list.extend(traceback.format_exception_only(sys.exc_info()[0], sys.exc_info()[1]))

        exception_str = "Traceback (most recent call last):\n"
        exception_str += "".join(exception_list)
        # Removing the last \n
        exception_str = exception_str[:-1]

        return exception_str

    def generate_from_idl(self, idl_file):
        try:
            idl_file_fullpath = os.path.realpath(idl_file)
            self.idl_compiler.compile_file(idl_file_fullpath)
        except Exception as err:
            print 'ERROR: idl_compiler.py: ' + os.path.basename(idl_file)
            print err
            print
            print 'Stack Dump:'
            print self.format_exception(err)

            return 1

    def generate_global(self):
        try:
            self.idl_compiler.generate_global()
        except Exception as err:
            print 'ERROR: idl_compiler.py generate global'
            print err
            print
            print 'Stack Dump:'
            print self.format_exception(err)

            return 1

        return 0


def main(argv):
    '''
    Runs Dart IDL code generator; IDL files.  IDL files same as GYP files in
    Source/bindings/core/core.gypi and Source/bindings/modules/modules.gypi (see
    idl_files.py on list of files).

    To run the PYTHONPATH should have the directories:

        Source/bindings/scripts
        Source/bindings/scripts/dart
    '''

    options = parse_options()

    if options.compute_idls:
        # TODO(terry): Assumes CWD is third_party/WebKit so any call to
        # full_path_NNNN is prefixing 'Source/core' to path.
        core_idls = full_path_core_idl_files()
        core_dependency_idls = full_path_core_dependency_idl_files()
        modules_idls = full_path_modules_idl_files()
        modules_dependency_idls = full_path_modules_dependency_idl_files()

        all_interfaces = core_idls + modules_idls
        all_dependencies = core_dependency_idls + modules_dependency_idls
        all_files = all_interfaces + all_dependencies

        # 2-stage computation: individual, then overall
        for idl_filename in all_files:
            compute_info_individual(idl_filename, 'dart')
        info_individuals = [info_individual()]
        compute_interfaces_info_overall(info_individuals)

        # Compile just IDLs with interfaces (no dependencies).
        if (options.output_directory == None):
            with ScopedTempFileProvider(keep=options.keep) as provider:
                build = Build(provider)
        else:
            provider = DirectoryProvider(path=options.output_directory)
            build = Build(provider)

        if options.verbose and options.keep:
            print 'Output directory %s created' % build.output_directory

        # Compile IDLs
        for filename in all_interfaces:
            if not filename.endswith('.idl'):
                continue
            if build.generate_from_idl(filename):
                return False

        if options.verbose:
            print '%s IDLs with interfaces processed' % len(all_interfaces)

        if options.verbose and not options.keep:
            print 'Output directory %s deleted' % build.output_directory

    if options.globals_only:
        if (options.output_directory == None):
            with ScopedTempFileProvider(keep=options.keep) as provider:
                build = Build(provider)
        else:
            provider = DirectoryProvider(path=options.output_directory)
            build = Build(provider)

        if options.verbose:
            print 'Generating global...'

        build.generate_global()

        if options.verbose:
            print 'Created DartWebkitClassIds .h/.cpp'


if __name__ == '__main__':
    sys.exit(main(sys.argv))
