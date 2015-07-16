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

import urllib
import zipfile

from webkitpy.common.net.networktransaction import NetworkTransaction
from webkitpy.common.system.fileset import FileSetFileHandle
from webkitpy.common.system.filesystem import FileSystem


class ZipFileSet(object):
    """The set of files in a zip file that resides at a URL (local or remote)"""
    def __init__(self, zip_url, filesystem=None, zip_factory=None):
        self._zip_url = zip_url
        self._temp_file = None
        self._zip_file = None
        self._filesystem = filesystem or FileSystem()
        self._zip_factory = zip_factory or self._retrieve_zip_file

    def _retrieve_zip_file(self, zip_url):
        temp_file = NetworkTransaction().run(lambda: urllib.urlretrieve(zip_url)[0])
        return (temp_file, zipfile.ZipFile(temp_file))

    def _load(self):
        if self._zip_file is None:
            self._temp_file, self._zip_file = self._zip_factory(self._zip_url)

    def open(self, filename):
        self._load()
        return FileSetFileHandle(self, filename, self._filesystem)

    def close(self):
        if self._temp_file:
            self._filesystem.remove(self._temp_file)
            self._temp_file = None

    def namelist(self):
        self._load()
        return self._zip_file.namelist()

    def read(self, filename):
        self._load()
        return self._zip_file.read(filename)

    def extract(self, filename, path):
        self._load()
        self._zip_file.extract(filename, path)

    def delete(self, filename):
        raise Exception("Can't delete from a ZipFileSet.")
