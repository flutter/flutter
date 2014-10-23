# Copyright (C) 2010 Google Inc. All rights reserved.
# Copyright (C) 2009 Torch Mobile Inc.
# Copyright (C) 2009 Apple Inc. All rights reserved.
# Copyright (C) 2010 Chris Jerdonek (chris.jerdonek@gmail.com)
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
from webkitpy.style.patchreader import PatchReader


class PatchReaderTest(unittest.TestCase):

    """Test the PatchReader class."""

    class MockTextFileReader(object):

        def __init__(self):
            self.passed_to_process_file = []
            """A list of (file_path, line_numbers) pairs."""
            self.delete_only_file_count = 0
            """A number of times count_delete_only_file() called"""

        def process_file(self, file_path, line_numbers):
            self.passed_to_process_file.append((file_path, line_numbers))

        def count_delete_only_file(self):
            self.delete_only_file_count += 1

    def setUp(self):
        file_reader = self.MockTextFileReader()
        self._file_reader = file_reader
        self._patch_checker = PatchReader(file_reader)

    def _call_check_patch(self, patch_string):
        self._patch_checker.check(patch_string)

    def _assert_checked(self, passed_to_process_file, delete_only_file_count):
        self.assertEqual(self._file_reader.passed_to_process_file,
                          passed_to_process_file)
        self.assertEqual(self._file_reader.delete_only_file_count,
                          delete_only_file_count)

    def test_check_patch(self):
        # The modified line_numbers array for this patch is: [2].
        self._call_check_patch("""diff --git a/__init__.py b/__init__.py
index ef65bee..e3db70e 100644
--- a/__init__.py
+++ b/__init__.py
@@ -1,1 +1,2 @@
 # Required for Python to search this directory for module files
+# New line
""")
        self._assert_checked([("__init__.py", [2])], 0)

    def test_check_patch_with_deletion(self):
        self._call_check_patch("""Index: __init__.py
===================================================================
--- __init__.py  (revision 3593)
+++ __init__.py  (working copy)
@@ -1 +0,0 @@
-foobar
""")
        # _mock_check_file should not be called for the deletion patch.
        self._assert_checked([], 1)

    def test_check_patch_with_png_deletion(self):
        fs = MockFileSystem()
        diff_text = """Index: tests/platform/mac/foo-expected.png
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = image/png
"""
        self._patch_checker.check(diff_text, fs)
        self._assert_checked([], 1)
