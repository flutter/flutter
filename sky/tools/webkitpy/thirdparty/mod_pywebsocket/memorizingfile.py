#!/usr/bin/env python
#
# Copyright 2011, Google Inc.
# All rights reserved.
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


"""Memorizing file.

A memorizing file wraps a file and memorizes lines read by readline.
"""


import sys


class MemorizingFile(object):
    """MemorizingFile wraps a file and memorizes lines read by readline.

    Note that data read by other methods are not memorized. This behavior
    is good enough for memorizing lines SimpleHTTPServer reads before
    the control reaches WebSocketRequestHandler.
    """

    def __init__(self, file_, max_memorized_lines=sys.maxint):
        """Construct an instance.

        Args:
            file_: the file object to wrap.
            max_memorized_lines: the maximum number of lines to memorize.
                Only the first max_memorized_lines are memorized.
                Default: sys.maxint.
        """

        self._file = file_
        self._memorized_lines = []
        self._max_memorized_lines = max_memorized_lines
        self._buffered = False
        self._buffered_line = None

    def __getattribute__(self, name):
        if name in ('_file', '_memorized_lines', '_max_memorized_lines',
                    '_buffered', '_buffered_line', 'readline',
                    'get_memorized_lines'):
            return object.__getattribute__(self, name)
        return self._file.__getattribute__(name)

    def readline(self, size=-1):
        """Override file.readline and memorize the line read.

        Note that even if size is specified and smaller than actual size,
        the whole line will be read out from underlying file object by
        subsequent readline calls.
        """

        if self._buffered:
            line = self._buffered_line
            self._buffered = False
        else:
            line = self._file.readline()
            if line and len(self._memorized_lines) < self._max_memorized_lines:
                self._memorized_lines.append(line)
        if size >= 0 and size < len(line):
            self._buffered = True
            self._buffered_line = line[size:]
            return line[:size]
        return line

    def get_memorized_lines(self):
        """Get lines memorized so far."""
        return self._memorized_lines


# vi:sts=4 sw=4 et
