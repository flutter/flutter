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

import sys
import unittest

from webkitpy.common.system.systemhost import SystemHost
from webkitpy.common.system.platforminfo import PlatformInfo
from webkitpy.common.system.platforminfo_mock import MockPlatformInfo
from webkitpy.common.system import path

class AbspathTest(unittest.TestCase):
    def platforminfo(self):
        return SystemHost().platform

    def test_abspath_to_uri_cygwin(self):
        if sys.platform != 'cygwin':
            return
        self.assertEqual(path.abspath_to_uri(self.platforminfo(), '/cygdrive/c/foo/bar.html'),
                          'file:///C:/foo/bar.html')

    def test_abspath_to_uri_unixy(self):
        self.assertEqual(path.abspath_to_uri(MockPlatformInfo(), "/foo/bar.html"),
                          'file:///foo/bar.html')

    def test_abspath_to_uri_win(self):
        if sys.platform != 'win32':
            return
        self.assertEqual(path.abspath_to_uri(self.platforminfo(), 'c:\\foo\\bar.html'),
                         'file:///c:/foo/bar.html')

    def test_abspath_to_uri_escaping_unixy(self):
        self.assertEqual(path.abspath_to_uri(MockPlatformInfo(), '/foo/bar + baz%?.html'),
                         'file:///foo/bar%20+%20baz%25%3F.html')

        # Note that you can't have '?' in a filename on windows.
    def test_abspath_to_uri_escaping_cygwin(self):
        if sys.platform != 'cygwin':
            return
        self.assertEqual(path.abspath_to_uri(self.platforminfo(), '/cygdrive/c/foo/bar + baz%.html'),
                          'file:///C:/foo/bar%20+%20baz%25.html')

    def test_stop_cygpath_subprocess(self):
        if sys.platform != 'cygwin':
            return

        # Call cygpath to ensure the subprocess is running.
        path.cygpath("/cygdrive/c/foo.txt")
        self.assertTrue(path._CygPath._singleton.is_running())

        # Stop it.
        path._CygPath.stop_cygpath_subprocess()

        # Ensure that it is stopped.
        self.assertFalse(path._CygPath._singleton.is_running())
