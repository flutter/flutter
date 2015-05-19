#!/usr/bin/python
# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Compile an .idl file to Blink C++ bindings (.h and .cpp files) for Dart:HTML.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

import abc
import os.path
import cPickle as pickle

from idl_reader import IdlReader
from utilities import write_file


def idl_filename_to_interface_name(idl_filename):
    basename = os.path.basename(idl_filename)
    interface_name, _ = os.path.splitext(basename)
    return interface_name


class IdlCompiler(object):
    """Abstract Base Class for IDL compilers.

    In concrete classes:
    * self.code_generator must be set, implementing generate_code()
      (returning a list of output code), and
    * compile_file() must be implemented (handling output filenames).
    """
    __metaclass__ = abc.ABCMeta

    def __init__(self, output_directory, code_generator=None,
                 interfaces_info=None, interfaces_info_filename='',
                 only_if_changed=False):
        """
        Args:
            interfaces_info:
                interfaces_info dict
                (avoids auxiliary file in run-bindings-tests)
            interfaces_info_file: filename of pickled interfaces_info
        """
        self.code_generator = code_generator
        if interfaces_info_filename:
            with open(interfaces_info_filename) as interfaces_info_file:
                interfaces_info = pickle.load(interfaces_info_file)
        self.interfaces_info = interfaces_info

        self.only_if_changed = only_if_changed
        self.output_directory = output_directory
        self.reader = IdlReader(interfaces_info, output_directory)

    def compile_and_write(self, idl_filename, output_filenames):
        interface_name = idl_filename_to_interface_name(idl_filename)
        idl_pickle_filename = os.path.join(self.output_directory,
                                           '%s_globals.pickle' % interface_name)
        definitions = self.reader.read_idl_definitions(idl_filename)
        output_code_list = self.code_generator.generate_code(definitions,
                                                             interface_name,
                                                             idl_filename,
                                                             idl_pickle_filename,
                                                             self.only_if_changed)

        for output_code, output_filename in zip(output_code_list, output_filenames):
            write_file(output_code, output_filename, self.only_if_changed)

    def generate_global_and_write(self, global_entries, output_filenames):
        output_code_list = self.code_generator.generate_globals(global_entries)
        for output_code, output_filename in zip(output_code_list, output_filenames):
            write_file(output_code, output_filename, self.only_if_changed)

    def generate_dart_blink_and_write(self, global_entries, output_filename):
        output_code = self.code_generator.generate_dart_blink(global_entries)
        write_file(output_code, output_filename, self.only_if_changed)

    @abc.abstractmethod
    def compile_file(self, idl_filename):
        pass
