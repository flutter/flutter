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

import platform
import sys
import unittest

from webkitpy.common.system.executive import Executive
from webkitpy.common.system.executive_mock import MockExecutive, MockExecutive2
from webkitpy.common.system.platforminfo import PlatformInfo


def fake_sys(platform_str='darwin', windows_version_tuple=None):

    class FakeSysModule(object):
        platform = platform_str
        if windows_version_tuple:
            getwindowsversion = lambda x: windows_version_tuple

    return FakeSysModule()


def fake_platform(mac_version_string='10.6.3', release_string='bar'):

    class FakePlatformModule(object):
        def mac_ver(self):
            return tuple([mac_version_string, tuple(['', '', '']), 'i386'])

        def platform(self):
            return 'foo'

        def release(self):
            return release_string

    return FakePlatformModule()


def fake_executive(output=None):
    if output:
        return MockExecutive2(output=output)
    return MockExecutive2(exception=SystemError)


class TestPlatformInfo(unittest.TestCase):
    def make_info(self, sys_module=None, platform_module=None, executive=None):
        return PlatformInfo(sys_module or fake_sys(), platform_module or fake_platform(), executive or fake_executive())

    def test_real_code(self):
        # This test makes sure the real (unmocked) code actually works.
        info = PlatformInfo(sys, platform, Executive())
        self.assertNotEquals(info.os_name, '')
        self.assertNotEquals(info.os_version, '')
        self.assertNotEquals(info.display_name(), '')
        self.assertTrue(info.is_mac() or info.is_win() or info.is_linux() or info.is_freebsd())
        self.assertIsNotNone(info.terminal_width())

        if info.is_mac():
            self.assertTrue(info.total_bytes_memory() > 0)
        else:
            self.assertIsNone(info.total_bytes_memory())

    def test_os_name_and_wrappers(self):
        info = self.make_info(fake_sys('linux2'))
        self.assertTrue(info.is_linux())
        self.assertFalse(info.is_mac())
        self.assertFalse(info.is_win())
        self.assertFalse(info.is_freebsd())

        info = self.make_info(fake_sys('linux3'))
        self.assertTrue(info.is_linux())
        self.assertFalse(info.is_mac())
        self.assertFalse(info.is_win())
        self.assertFalse(info.is_freebsd())

        info = self.make_info(fake_sys('darwin'), fake_platform('10.6.3'))
        self.assertEqual(info.os_name, 'mac')
        self.assertFalse(info.is_linux())
        self.assertTrue(info.is_mac())
        self.assertFalse(info.is_win())
        self.assertFalse(info.is_freebsd())

        info = self.make_info(fake_sys('win32', tuple([6, 1, 7600])))
        self.assertEqual(info.os_name, 'win')
        self.assertFalse(info.is_linux())
        self.assertFalse(info.is_mac())
        self.assertTrue(info.is_win())
        self.assertFalse(info.is_freebsd())

        info = self.make_info(fake_sys('cygwin'), executive=fake_executive('6.1.7600'))
        self.assertEqual(info.os_name, 'win')
        self.assertFalse(info.is_linux())
        self.assertFalse(info.is_mac())
        self.assertTrue(info.is_win())
        self.assertFalse(info.is_freebsd())

        info = self.make_info(fake_sys('freebsd8'))
        self.assertEqual(info.os_name, 'freebsd')
        self.assertFalse(info.is_linux())
        self.assertFalse(info.is_mac())
        self.assertFalse(info.is_win())
        self.assertTrue(info.is_freebsd())

        self.assertRaises(AssertionError, self.make_info, fake_sys('vms'))

    def test_os_version(self):
        self.assertRaises(AssertionError, self.make_info, fake_sys('darwin'), fake_platform('10.4.3'))
        self.assertEqual(self.make_info(fake_sys('darwin'), fake_platform('10.5.1')).os_version, 'leopard')
        self.assertEqual(self.make_info(fake_sys('darwin'), fake_platform('10.6.1')).os_version, 'snowleopard')
        self.assertEqual(self.make_info(fake_sys('darwin'), fake_platform('10.7.1')).os_version, 'lion')
        self.assertEqual(self.make_info(fake_sys('darwin'), fake_platform('10.8.1')).os_version, 'mountainlion')
        self.assertEqual(self.make_info(fake_sys('darwin'), fake_platform('10.9.0')).os_version, 'mavericks')
        self.assertEqual(self.make_info(fake_sys('darwin'), fake_platform('10.10.0')).os_version, 'future')

        self.assertEqual(self.make_info(fake_sys('linux2')).os_version, 'lucid')

        self.assertEqual(self.make_info(fake_sys('freebsd8'), fake_platform('', '8.3-PRERELEASE')).os_version, '8.3-PRERELEASE')
        self.assertEqual(self.make_info(fake_sys('freebsd9'), fake_platform('', '9.0-RELEASE')).os_version, '9.0-RELEASE')

        self.assertRaises(AssertionError, self.make_info, fake_sys('win32', tuple([5, 0, 1234])))
        self.assertEqual(self.make_info(fake_sys('win32', tuple([6, 2, 1234]))).os_version, 'future')
        self.assertEqual(self.make_info(fake_sys('win32', tuple([6, 1, 7600]))).os_version, '7sp0')
        self.assertEqual(self.make_info(fake_sys('win32', tuple([6, 0, 1234]))).os_version, 'vista')
        self.assertEqual(self.make_info(fake_sys('win32', tuple([5, 1, 1234]))).os_version, 'xp')

        self.assertRaises(AssertionError, self.make_info, fake_sys('win32'), executive=fake_executive('5.0.1234'))
        self.assertEqual(self.make_info(fake_sys('cygwin'), executive=fake_executive('6.2.1234')).os_version, 'future')
        self.assertEqual(self.make_info(fake_sys('cygwin'), executive=fake_executive('6.1.7600')).os_version, '7sp0')
        self.assertEqual(self.make_info(fake_sys('cygwin'), executive=fake_executive('6.0.1234')).os_version, 'vista')
        self.assertEqual(self.make_info(fake_sys('cygwin'), executive=fake_executive('5.1.1234')).os_version, 'xp')

    def test_display_name(self):
        info = self.make_info(fake_sys('darwin'))
        self.assertNotEquals(info.display_name(), '')

        info = self.make_info(fake_sys('win32', tuple([6, 1, 7600])))
        self.assertNotEquals(info.display_name(), '')

        info = self.make_info(fake_sys('linux2'))
        self.assertNotEquals(info.display_name(), '')

        info = self.make_info(fake_sys('freebsd9'))
        self.assertNotEquals(info.display_name(), '')

    def test_total_bytes_memory(self):
        info = self.make_info(fake_sys('darwin'), fake_platform('10.6.3'), fake_executive('1234'))
        self.assertEqual(info.total_bytes_memory(), 1234)

        info = self.make_info(fake_sys('win32', tuple([6, 1, 7600])))
        self.assertIsNone(info.total_bytes_memory())

        info = self.make_info(fake_sys('linux2'))
        self.assertIsNone(info.total_bytes_memory())

        info = self.make_info(fake_sys('freebsd9'))
        self.assertIsNone(info.total_bytes_memory())
