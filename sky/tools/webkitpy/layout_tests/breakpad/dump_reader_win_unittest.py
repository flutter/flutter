# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
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

from webkitpy.common.host_mock import MockHost
from webkitpy.common.system.executive_mock import MockExecutive
from webkitpy.layout_tests.breakpad.dump_reader_win import DumpReaderWin


class TestDumpReaderWin(unittest.TestCase):
    def test_check_is_functional_cdb_not_found(self):
        host = MockHost()
        host.executive = MockExecutive(should_throw=True)

        build_dir = "/mock-checkout/out/Debug"
        host.filesystem.maybe_make_directory(build_dir)
        dump_reader = DumpReaderWin(host, build_dir)

        self.assertFalse(dump_reader.check_is_functional())

    def test_get_pid_from_dump(self):
        host = MockHost()

        dump_file = '/crash-dumps/dump.txt'
        expected_pid = '4711'
        host.filesystem.write_text_file(dump_file, 'channel:\npid:%s\nplat:Win32\nprod:content_shell\n' % expected_pid)
        build_dir = "/mock-checkout/out/Debug"
        host.filesystem.maybe_make_directory(build_dir)
        dump_reader = DumpReaderWin(host, build_dir)

        self.assertTrue(dump_reader.check_is_functional())
        self.assertEqual(expected_pid, dump_reader._get_pid_from_dump(dump_file))

    def test_get_stack_from_dump(self):
        host = MockHost()

        dump_file = '/crash-dumps/dump.dmp'
        real_dump_file = '/crash-dumps/dump.dmp'
        host.filesystem.write_text_file(dump_file, 'product:content_shell\n')
        host.filesystem.write_binary_file(real_dump_file, 'MDMP')
        build_dir = "/mock-checkout/out/Debug"
        host.filesystem.maybe_make_directory(build_dir)
        dump_reader = DumpReaderWin(host, build_dir)

        self.assertTrue(dump_reader.check_is_functional())
        host.executive.calls = []
        self.assertEqual("MOCK output of child process", dump_reader._get_stack_from_dump(dump_file))
        self.assertEqual(1, len(host.executive.calls))
        cmd_line = " ".join(host.executive.calls[0])
        self.assertIn('cdb.exe', cmd_line)
        self.assertIn(real_dump_file, cmd_line)
