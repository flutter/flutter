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

from webkitpy.common.system.filesystem import FileSystem


class FileSetFileHandle(object):
    """Points to a file that resides in a file set"""
    def __init__(self, fileset, filename, filesystem=None):
        self._filename = filename
        self._fileset = fileset
        self._contents = None
        self._filesystem = filesystem or FileSystem()

    def __str__(self):
        return "%s:%s" % (self._fileset, self._filename)

    def close(self):
        pass

    def contents(self):
        if self._contents is None:
            self._contents = self._fileset.read(self._filename)
        return self._contents

    def save_to(self, path, filename=None):
        if filename is None:
            self._fileset.extract(self._filename, path)
            return
        with self._filesystem.mkdtemp() as temp_dir:
            self._fileset.extract(self._filename, temp_dir)

            src = self._filesystem.join(temp_dir, self._filename)
            dest = self._filesystem.join(path, filename)
            self._filesystem.copyfile(src, dest)

    def delete(self):
        self._fileset.delete(self._filename)

    def name(self):
        return self._filename

    def splitext(self):
        return self._filesystem.splitext(self.name())
