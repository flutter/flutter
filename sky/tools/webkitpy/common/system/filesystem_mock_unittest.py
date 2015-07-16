# Copyright (C) 2011 Google Inc. All rights reserved.
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

import os
import re
import unittest


from webkitpy.common.system import filesystem_mock
from webkitpy.common.system import filesystem_unittest


class MockFileSystemTest(unittest.TestCase, filesystem_unittest.GenericFileSystemTests):
    def setUp(self):
        self.fs = filesystem_mock.MockFileSystem()
        self.setup_generic_test_dir()

    def tearDown(self):
        self.teardown_generic_test_dir()
        self.fs = None

    def quick_check(self, test_fn, good_fn, *tests):
        for test in tests:
            if hasattr(test, '__iter__'):
                expected = good_fn(*test)
                actual = test_fn(*test)
            else:
                expected = good_fn(test)
                actual = test_fn(test)
            self.assertEqual(expected, actual, 'given %s, expected %s, got %s' % (repr(test), repr(expected), repr(actual)))

    def test_join(self):
        self.quick_check(self.fs.join,
                         self.fs._slow_but_correct_join,
                         ('',),
                         ('', 'bar'),
                         ('foo',),
                         ('foo/',),
                         ('foo', ''),
                         ('foo/', ''),
                         ('foo', 'bar'),
                         ('foo', '/bar'),
                         )

    def test_normpath(self):
        self.quick_check(self.fs.normpath,
                         self.fs._slow_but_correct_normpath,
                         '',
                         '/',
                         '.',
                         '/.',
                         'foo',
                         'foo/',
                         'foo/.',
                         'foo/bar',
                         '/foo',
                         'foo/../bar',
                         'foo/../bar/baz',
                         '../foo')

    def test_relpath_win32(self):
        pass
