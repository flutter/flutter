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

import unittest

from webkitpy.common.system import executive_mock
from webkitpy.common.system.systemhost_mock import MockSystemHost
from webkitpy.tool.mocktool import MockOptions

from webkitpy.layout_tests.port import linux
from webkitpy.layout_tests.port import port_testcase


class LinuxPortTest(port_testcase.PortTestCase):
    port_name = 'linux'
    port_maker = linux.LinuxPort

    def assert_architecture(self, port_name=None, file_output=None, expected_architecture=None):
        host = MockSystemHost()
        host.filesystem.isfile = lambda x: 'content_shell' in x
        if file_output:
            host.executive = executive_mock.MockExecutive2(file_output)

        port = self.make_port(host, port_name=port_name)
        self.assertEqual(port.architecture(), expected_architecture)
        if expected_architecture == 'x86':
            self.assertTrue(port.baseline_path().endswith('linux-x86'))
            self.assertTrue(port.baseline_search_path()[0].endswith('linux-x86'))
            self.assertTrue(port.baseline_search_path()[1].endswith('linux'))
        else:
            self.assertTrue(port.baseline_path().endswith('linux'))
            self.assertTrue(port.baseline_search_path()[0].endswith('linux'))

    def test_architectures(self):
        self.assert_architecture(port_name='linux-x86',
                                 expected_architecture='x86')
        self.assert_architecture(port_name='linux-x86_64',
                                 expected_architecture='x86_64')
        self.assert_architecture(file_output='ELF 32-bit LSB executable',
                                 expected_architecture='x86')
        self.assert_architecture(file_output='ELF 64-bit LSB      executable',
                                 expected_architecture='x86_64')

    def test_check_illegal_port_names(self):
        # FIXME: Check that, for now, these are illegal port names.
        # Eventually we should be able to do the right thing here.
        self.assertRaises(AssertionError, linux.LinuxPort, MockSystemHost(), port_name='x86-linux')

    def test_determine_architecture_fails(self):
        # Test that we default to 'x86' if the driver doesn't exist.
        port = self.make_port()
        self.assertEqual(port.architecture(), 'x86_64')

        # Test that we default to 'x86' on an unknown architecture.
        host = MockSystemHost()
        host.filesystem.exists = lambda x: True
        host.executive = executive_mock.MockExecutive2('win32')
        port = self.make_port(host=host)
        self.assertEqual(port.architecture(), 'x86_64')

        # Test that we raise errors if something weird happens.
        host.executive = executive_mock.MockExecutive2(exception=AssertionError)
        self.assertRaises(AssertionError, linux.LinuxPort, host, '%s-foo' % self.port_name)

    def test_operating_system(self):
        self.assertEqual('linux', self.make_port().operating_system())

    def test_build_path(self):
        # Test that optional paths are used regardless of whether they exist.
        options = MockOptions(configuration='Release', build_directory='/foo')
        self.assert_build_path(options, ['/mock-checkout/out/Release'], '/foo/Release')

        # Test that optional relative paths are returned unmodified.
        options = MockOptions(configuration='Release', build_directory='foo')
        self.assert_build_path(options, ['/mock-checkout/out/Release'], 'foo/Release')

    def test_driver_name_option(self):
        self.assertTrue(self.make_port()._path_to_driver().endswith('content_shell'))
        self.assertTrue(self.make_port(options=MockOptions(driver_name='OtherDriver'))._path_to_driver().endswith('OtherDriver'))

    def test_path_to_image_diff(self):
        self.assertEqual(self.make_port()._path_to_image_diff(), '/mock-checkout/out/Release/image_diff')
