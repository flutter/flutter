# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from webkitpy.common.system.fileset import FileSetFileHandle
from webkitpy.common.system.filesystem_mock import MockFileSystem


class MockZip(object):
    """A mock zip file that can have new files inserted into it."""
    def __init__(self, filesystem=None):
        self._filesystem = filesystem or MockFileSystem()
        self._files = {}

    def __str__(self):
        return "MockZip"

    def insert(self, filename, content):
        self._files[filename] = content

    def namelist(self):
        return self._files.keys()

    def open(self, filename):
        return FileSetFileHandle(self, filename)

    def read(self, filename):
        return self._files[filename]

    def extract(self, filename, path):
        full_path = self._filesystem.join(path, filename)
        contents = self.open(filename).contents()
        self._filesystem.write_text_file(full_path, contents)

    def delete(self, filename):
        self._files[filename] = None
