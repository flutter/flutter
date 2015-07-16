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

import cgi

from webkitpy.common.host import Host
from webkitpy.common.host_mock import MockHost
from webkitpy.common.system.executive_mock import MockExecutive
from webkitpy.layout_tests.breakpad.dump_reader_multipart import DumpReaderMultipart


class TestDumpReaderMultipart(unittest.TestCase):
    _MULTIPART_DUMP = [
        '--boundary',
        'Content-Disposition: form-data; name="prod"',
        '',
        'content_shell',
        '--boundary',
        'Content-Disposition: form-data; name="pid"',
        '',
        '4711',
        '--boundary',
        'Content-Disposition: form-data; name="upload_file_minidump"; filename="dump"',
        'Content-Type: application/octet-stream',
        '',
        'MDMP',
        '--boundary--',
    ]

    def test_check_generate_breakpad_symbols_actually_exists(self):
        host = Host()
        dump_reader = DumpReaderMultipart(host, build_dir=None)
        self.assertTrue(host.filesystem.exists(dump_reader._path_to_generate_breakpad_symbols()))

    def test_check_is_functional_breakpad_tools_not_found(self):
        host = MockHost()

        build_dir = "/mock-checkout/out/Debug"
        host.filesystem.maybe_make_directory(build_dir)
        dump_reader = DumpReaderMultipart(host, build_dir)
        dump_reader._file_extension = lambda: 'dmp'
        dump_reader._binaries_to_symbolize = lambda: ['content_shell']

        self.assertFalse(dump_reader.check_is_functional())

    def test_get_pid_from_dump(self):
        host = MockHost()

        dump_file = '/crash-dumps/dump.dmp'
        expected_pid = '4711'
        host.filesystem.write_text_file(dump_file, "\r\n".join(TestDumpReaderMultipart._MULTIPART_DUMP))
        build_dir = "/mock-checkout/out/Debug"
        host.filesystem.maybe_make_directory(build_dir)
        host.filesystem.exists = lambda x: True

        # The mock file object returned by open_binary_file_for_reading doesn't
        # have readline(), however, the real File object does.
        host.filesystem.open_binary_file_for_reading = host.filesystem.open_text_file_for_reading
        dump_reader = DumpReaderMultipart(host, build_dir)
        dump_reader._file_extension = lambda: 'dmp'
        dump_reader._binaries_to_symbolize = lambda: ['content_shell']

        self.assertTrue(dump_reader.check_is_functional())
        self.assertEqual(expected_pid, dump_reader._get_pid_from_dump(dump_file))

    def test_get_stack_from_dump(self):
        host = MockHost()

        dump_file = '/crash-dumps/dump.dmp'
        host.filesystem.write_text_file(dump_file, "\r\n".join(TestDumpReaderMultipart._MULTIPART_DUMP))
        build_dir = "/mock-checkout/out/Debug"
        host.filesystem.maybe_make_directory(build_dir)
        host.filesystem.exists = lambda x: True

        # The mock file object returned by open_binary_file_for_reading doesn't
        # have readline(), however, the real File object does.
        host.filesystem.open_binary_file_for_reading = host.filesystem.open_text_file_for_reading
        dump_reader = DumpReaderMultipart(host, build_dir)
        dump_reader._file_extension = lambda: 'dmp'
        dump_reader._binaries_to_symbolize = lambda: ['content_shell']

        self.assertTrue(dump_reader.check_is_functional())
        self.assertEqual("MOCK output of child process", dump_reader._get_stack_from_dump(dump_file))
        self.assertEqual(2, len(host.executive.calls))
        cmd_line = " ".join(host.executive.calls[0])
        self.assertIn('generate_breakpad_symbols.py', cmd_line)
        cmd_line = " ".join(host.executive.calls[1])
        self.assertIn('minidump_stackwalk', cmd_line)
