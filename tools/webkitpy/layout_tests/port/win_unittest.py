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

import os
import unittest

from webkitpy.common.system import outputcapture
from webkitpy.common.system.executive_mock import MockExecutive
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.layout_tests.port import port_testcase
from webkitpy.layout_tests.port import win
from webkitpy.tool.mocktool import MockOptions


class WinPortTest(port_testcase.PortTestCase):
    port_name = 'win'
    port_maker = win.WinPort
    os_name = 'win'
    os_version = 'xp'

    def test_setup_environ_for_server(self):
        port = self.make_port()
        port._executive = MockExecutive(should_log=True)
        output = outputcapture.OutputCapture()
        # FIXME: This test should not use the real os.environ
        orig_environ = os.environ.copy()
        env = output.assert_outputs(self, port.setup_environ_for_server)
        self.assertEqual(orig_environ["PATH"], os.environ["PATH"])
        self.assertNotEqual(env["PATH"], os.environ["PATH"])

    def test_setup_environ_for_server_cygpath(self):
        port = self.make_port()
        env = port.setup_environ_for_server(port.driver_name())
        self.assertEqual(env['CYGWIN_PATH'], '/mock-checkout/third_party/cygwin/bin')

    def test_setup_environ_for_server_register_cygwin(self):
        port = self.make_port(options=MockOptions(register_cygwin=True, results_directory='/'))
        port._executive = MockExecutive(should_log=True)
        expected_logs = "MOCK run_command: ['/mock-checkout/third_party/cygwin/setup_mount.bat'], cwd=None\n"
        output = outputcapture.OutputCapture()
        output.assert_outputs(self, port.setup_environ_for_server, expected_logs=expected_logs)

    def assert_name(self, port_name, os_version_string, expected):
        port = self.make_port(port_name=port_name, os_version=os_version_string)
        self.assertEqual(expected, port.name())

    def test_versions(self):
        port = self.make_port()
        self.assertIn(port.name(), ('win-xp', 'win-win7'))

        self.assert_name(None, 'xp', 'win-xp')
        self.assert_name('win', 'xp', 'win-xp')
        self.assert_name('win-xp', 'xp', 'win-xp')
        self.assert_name('win-xp', '7sp0', 'win-xp')

        self.assert_name(None, '7sp0', 'win-win7')
        self.assert_name(None, 'vista', 'win-win7')
        self.assert_name('win', '7sp0', 'win-win7')
        self.assert_name('win-win7', 'xp', 'win-win7')
        self.assert_name('win-win7', '7sp0', 'win-win7')
        self.assert_name('win-win7', 'vista', 'win-win7')

        self.assertRaises(AssertionError, self.assert_name, None, 'w2k', 'win-xp')

    def test_baseline_path(self):
        port = self.make_port(port_name='win-xp')
        self.assertEqual(port.baseline_path(), port._webkit_baseline_path('win-xp'))

        port = self.make_port(port_name='win-win7')
        self.assertEqual(port.baseline_path(), port._webkit_baseline_path('win'))

    def test_build_path(self):
        # Test that optional paths are used regardless of whether they exist.
        options = MockOptions(configuration='Release', build_directory='/foo')
        self.assert_build_path(options, ['/mock-checkout/out/Release'], '/foo/Release')

        # Test that optional relative paths are returned unmodified.
        options = MockOptions(configuration='Release', build_directory='foo')
        self.assert_build_path(options, ['/mock-checkout/out/Release'], 'foo/Release')

        # Test that we prefer the legacy dir over the new dir.
        options = MockOptions(configuration='Release', build_directory=None)
        self.assert_build_path(options, ['/mock-checkout/build/Release', '/mock-checkout/out'], '/mock-checkout/build/Release')

    def test_build_path_timestamps(self):
        options = MockOptions(configuration='Release', build_directory=None)
        port = self.make_port(options=options)
        port.host.filesystem.maybe_make_directory('/mock-checkout/out/Release')
        port.host.filesystem.maybe_make_directory('/mock-checkout/build/Release')
        # Check with 'out' being newer.
        port.host.filesystem.mtime = lambda f: 5 if '/out/' in f else 4
        self.assertEqual(port._build_path(), '/mock-checkout/out/Release')
        # Check with 'build' being newer.
        port.host.filesystem.mtime = lambda f: 5 if '/build/' in f else 4
        self.assertEqual(port._build_path(), '/mock-checkout/build/Release')

    def test_operating_system(self):
        self.assertEqual('win', self.make_port().operating_system())

    def test_driver_name_option(self):
        self.assertTrue(self.make_port()._path_to_driver().endswith('content_shell.exe'))
        self.assertTrue(self.make_port(options=MockOptions(driver_name='OtherDriver'))._path_to_driver().endswith('OtherDriver.exe'))

    def test_path_to_image_diff(self):
        self.assertEqual(self.make_port()._path_to_image_diff(), '/mock-checkout/out/Release/image_diff.exe')
