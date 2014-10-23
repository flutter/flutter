# Copyright (c) 2009, Google Inc. All rights reserved.
# Copyright (c) 2009 Apple Inc. All rights reserved.
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

import codecs
import os
import sys


# Simple class to split output between multiple destinations
class Tee:
    def __init__(self, *files):
        self.files = files

    # Callers should pass an already encoded string for writing.
    def write(self, bytes):
        for file in self.files:
            file.write(bytes)


class OutputTee:
    def __init__(self):
        self._original_stdout = None
        self._original_stderr = None
        self._files_for_output = []

    def add_log(self, path):
        log_file = self._open_log_file(path)
        self._files_for_output.append(log_file)
        self._tee_outputs_to_files(self._files_for_output)
        return log_file

    def remove_log(self, log_file):
        self._files_for_output.remove(log_file)
        self._tee_outputs_to_files(self._files_for_output)
        log_file.close()

    @staticmethod
    def _open_log_file(log_path):
        (log_directory, log_name) = os.path.split(log_path)
        if log_directory and not os.path.exists(log_directory):
            os.makedirs(log_directory)
        return codecs.open(log_path, "a+", "utf-8")

    def _tee_outputs_to_files(self, files):
        if not self._original_stdout:
            self._original_stdout = sys.stdout
            self._original_stderr = sys.stderr
        if files and len(files):
            sys.stdout = Tee(self._original_stdout, *files)
            sys.stderr = Tee(self._original_stderr, *files)
        else:
            sys.stdout = self._original_stdout
            sys.stderr = self._original_stderr
