# Copyright (C) 2011, Google Inc. All rights reserved.
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
#
# WebKit's Python module for parsing and modifying ChangeLog files

import codecs
import fileinput
import re
import textwrap


class DEPS(object):

    _variable_regexp = r"\s+'%s':\s+'(?P<value>\d+)'"

    def __init__(self, path):
        # FIXME: This should take a FileSystem object.
        self._path = path

    def read_variable(self, name):
        pattern = re.compile(self._variable_regexp % name)
        for line in fileinput.FileInput(self._path):
            match = pattern.match(line)
            if match:
                return int(match.group("value"))

    def write_variable(self, name, value):
        pattern = re.compile(self._variable_regexp % name)
        replacement_line = "  '%s': '%s'" % (name, value)
        # inplace=1 creates a backup file and re-directs stdout to the file
        for line in fileinput.FileInput(self._path, inplace=1):
            if pattern.match(line):
                print replacement_line
                continue
            # Trailing comma suppresses printing newline
            print line,
