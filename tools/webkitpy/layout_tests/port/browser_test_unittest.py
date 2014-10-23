# Copyright (C) 2014 Google Inc. All rights reserved.
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

from webkitpy.common.system.executive_mock import MockExecutive2
from webkitpy.common.system.systemhost_mock import MockSystemHost
from webkitpy.tool.mocktool import MockOptions

from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.port import browser_test
from webkitpy.layout_tests.port import port_testcase
from webkitpy.layout_tests.port import browser_test_driver


class BrowserTestLinuxTest(port_testcase.PortTestCase):
    port_name = 'linux'
    port_maker = browser_test.BrowserTestLinuxPort

    def test_driver_name_option(self):
        self.assertTrue(self.make_port(options=MockOptions(driver_name='browser_tests'))._path_to_driver().endswith('browser_tests'))

    def test_layout_tests_dir(self):
        self.assertTrue(self.make_port().layout_tests_dir().endswith('chrome/test/data/printing/layout_tests'))

    def test_driver_type(self):
        self.assertTrue(isinstance(self.make_port(options=MockOptions(driver_name='browser_tests')).create_driver(1), browser_test_driver.BrowserTestDriver))

    def test_check_sys_deps(self):
        port = self.make_port()
        port._executive = MockExecutive2(exit_code=0)
        self.assertEqual(port.check_sys_deps(needs_http=False), test_run_results.OK_EXIT_STATUS)

    def test_default_timeout_ms(self):
        self.assertEqual(self.make_port(options=MockOptions(configuration='Release')).default_timeout_ms(), 10000)
        self.assertEqual(self.make_port(options=MockOptions(configuration='Debug')).default_timeout_ms(), 30000)


class BrowserTestWinTest(port_testcase.PortTestCase):
    port_name = 'win'
    port_maker = browser_test.BrowserTestWinPort
    os_name = 'win'
    os_version = 'xp'

    def test_driver_name_option(self):
        self.assertTrue(self.make_port(options=MockOptions(driver_name='browser_tests'))._path_to_driver().endswith('browser_tests.exe'))

    def test_layout_tests_dir(self):
        self.assertTrue(self.make_port().layout_tests_dir().endswith('chrome/test/data/printing/layout_tests'))

    def test_driver_type(self):
        self.assertTrue(isinstance(self.make_port(options=MockOptions(driver_name='browser_tests')).create_driver(1), browser_test_driver.BrowserTestDriver))

    def test_check_sys_deps(self):
        port = self.make_port()
        port._executive = MockExecutive2(exit_code=0)
        self.assertEqual(port.check_sys_deps(needs_http=False), test_run_results.OK_EXIT_STATUS)

    def test_default_timeout_ms(self):
        self.assertEqual(self.make_port(options=MockOptions(configuration='Release')).default_timeout_ms(), 20000)
        self.assertEqual(self.make_port(options=MockOptions(configuration='Debug')).default_timeout_ms(), 60000)


class BrowserTestMacTest(port_testcase.PortTestCase):
    os_name = 'mac'
    os_version = 'snowleopard'
    port_name = 'mac'
    port_maker = browser_test.BrowserTestMacPort

    def test_driver_name_option(self):
        self.assertTrue(self.make_port(options=MockOptions(driver_name='browser_tests'))._path_to_driver().endswith('browser_tests'))

    def test_layout_tests_dir(self):
        self.assertTrue(self.make_port().layout_tests_dir().endswith('chrome/test/data/printing/layout_tests'))

    def test_driver_type(self):
        self.assertTrue(isinstance(self.make_port(options=MockOptions(driver_name='browser_tests')).create_driver(1), browser_test_driver.BrowserTestDriver))

    def test_driver_path(self):
        test_port = self.make_port(options=MockOptions(driver_name='browser_tests'))
        self.assertFalse('.app/Contents/MacOS' in test_port._path_to_driver())

    def test_check_sys_deps(self):
        port = self.make_port()
        port._executive = MockExecutive2(exit_code=0)
        self.assertEqual(port.check_sys_deps(needs_http=False), test_run_results.OK_EXIT_STATUS)

    def test_default_timeout_ms(self):
        self.assertEqual(self.make_port(options=MockOptions(configuration='Release')).default_timeout_ms(), 20000)
        self.assertEqual(self.make_port(options=MockOptions(configuration='Debug')).default_timeout_ms(), 60000)
