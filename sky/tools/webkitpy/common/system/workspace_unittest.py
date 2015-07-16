# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

import unittest

from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.common.system.workspace import Workspace
from webkitpy.common.system.executive_mock import MockExecutive


class WorkspaceTest(unittest.TestCase):

    def test_find_unused_filename(self):
        filesystem = MockFileSystem({
            "dir/foo.jpg": "",
            "dir/foo-1.jpg": "",
            "dir/foo-2.jpg": "",
        })
        workspace = Workspace(filesystem, None)
        self.assertEqual(workspace.find_unused_filename("bar", "bar", "bar"), "bar/bar.bar")
        self.assertEqual(workspace.find_unused_filename("dir", "foo", "jpg", search_limit=1), None)
        self.assertEqual(workspace.find_unused_filename("dir", "foo", "jpg", search_limit=2), None)
        self.assertEqual(workspace.find_unused_filename("dir", "foo", "jpg"), "dir/foo-3.jpg")

    def test_create_zip(self):
        workspace = Workspace(None, MockExecutive(should_log=True))
        expected_logs = "MOCK run_command: ['zip', '-9', '-r', '/zip/path', '.'], cwd=/source/path\n"
        class MockZipFile(object):
            def __init__(self, path):
                self.filename = path
        archive = OutputCapture().assert_outputs(self, workspace.create_zip, ["/zip/path", "/source/path", MockZipFile], expected_logs=expected_logs)
        self.assertEqual(archive.filename, "/zip/path")

    def test_create_zip_exception(self):
        workspace = Workspace(None, MockExecutive(should_log=True, should_throw=True))
        expected_logs = """MOCK run_command: ['zip', '-9', '-r', '/zip/path', '.'], cwd=/source/path
Workspace.create_zip failed in /source/path:
MOCK ScriptError

output: MOCK output of child process
"""
        class MockZipFile(object):
            def __init__(self, path):
                self.filename = path
        archive = OutputCapture().assert_outputs(self, workspace.create_zip, ["/zip/path", "/source/path", MockZipFile], expected_logs=expected_logs)
        self.assertIsNone(archive)
