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

import shutil
import tempfile
import unittest
import zipfile

from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.zipfileset import ZipFileSet


class FakeZip(object):
    def __init__(self, filesystem):
        self._filesystem = filesystem
        self._files = {}

    def add_file(self, filename, contents):
        self._files[filename] = contents

    def open(self, filename):
        return FileSetFileHandle(self, filename, self._filesystem)

    def namelist(self):
        return self._files.keys()

    def read(self, filename):
        return self._files[filename]

    def extract(self, filename, path):
        self._filesystem.write_text_file(self._filesystem.join(path, filename), self.read(filename))

    def delete(self, filename):
        raise Exception("Can't delete from a ZipFileSet.")


class ZipFileSetTest(unittest.TestCase):
    def setUp(self):
        self._filesystem = MockFileSystem()
        self._zip = ZipFileSet('blah', self._filesystem, self.make_fake_zip)

    def make_fake_zip(self, zip_url):
        result = FakeZip(self._filesystem)
        result.add_file('some-file', 'contents')
        result.add_file('a/b/some-other-file', 'other contents')
        return (None, result)

    def test_open(self):
        file = self._zip.open('a/b/some-other-file')
        self.assertEqual('a/b/some-other-file', file.name())
        self.assertEqual('other contents', file.contents())

    def test_close(self):
        zipfileset = ZipFileSet('blah', self._filesystem, self.make_fake_zip)
        zipfileset.close()

    def test_read(self):
        self.assertEqual('contents', self._zip.read('some-file'))

    def test_extract(self):
        self._filesystem.maybe_make_directory('/some-dir')
        self._zip.extract('some-file', '/some-dir')
        self.assertTrue(self._filesystem.isfile('/some-dir/some-file'))

    def test_deep_extract(self):
        self._filesystem.maybe_make_directory('/some-dir')
        self._zip.extract('a/b/some-other-file', '/some-dir')
        self.assertTrue(self._filesystem.isfile('/some-dir/a/b/some-other-file'))

    def test_cant_delete(self):
        self.assertRaises(Exception, self._zip.delete, 'some-file')

    def test_namelist(self):
        self.assertTrue('some-file' in self._zip.namelist())
