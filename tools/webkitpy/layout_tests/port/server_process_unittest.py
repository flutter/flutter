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

import sys
import time
import unittest

from webkitpy.layout_tests.port.factory import PortFactory
from webkitpy.layout_tests.port import server_process
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.common.system.systemhost_mock import MockSystemHost
from webkitpy.common.system.outputcapture import OutputCapture


class TrivialMockPort(object):
    def __init__(self):
        self.host = MockSystemHost()
        self.host.executive.kill_process = lambda x: None
        self.host.executive.kill_process = lambda x: None

    def results_directory(self):
        return "/mock-results"

    def process_kill_time(self):
        return 1


class MockFile(object):
    def __init__(self, server_process):
        self._server_process = server_process
        self.closed = False

    def fileno(self):
        return 1

    def write(self, line):
        self._server_process.broken_pipes.append(self)
        raise IOError

    def close(self):
        self.closed = True


class MockProc(object):
    def __init__(self, server_process):
        self.stdin = MockFile(server_process)
        self.stdout = MockFile(server_process)
        self.stderr = MockFile(server_process)
        self.pid = 1

    def poll(self):
        return 1

    def wait(self):
        return 0


class FakeServerProcess(server_process.ServerProcess):
    def _start(self):
        self._proc = MockProc(self)
        self.stdin = self._proc.stdin
        self.stdout = self._proc.stdout
        self.stderr = self._proc.stderr
        self._pid = self._proc.pid
        self.broken_pipes = []


class TestServerProcess(unittest.TestCase):
    def test_basic(self):
        cmd = [sys.executable, '-c', 'import sys; import time; time.sleep(0.02); print "stdout"; sys.stdout.flush(); print >>sys.stderr, "stderr"']
        host = SystemHost()
        factory = PortFactory(host)
        port = factory.get()
        now = time.time()
        proc = server_process.ServerProcess(port, 'python', cmd)
        proc.write('')

        self.assertEqual(proc.poll(), None)
        self.assertFalse(proc.has_crashed())

        # check that doing a read after an expired deadline returns
        # nothing immediately.
        line = proc.read_stdout_line(now - 1)
        self.assertEqual(line, None)

        # FIXME: This part appears to be flaky. line should always be non-None.
        # FIXME: https://bugs.webkit.org/show_bug.cgi?id=88280
        line = proc.read_stdout_line(now + 1.0)
        if line:
            self.assertEqual(line.strip(), "stdout")

        line = proc.read_stderr_line(now + 1.0)
        if line:
            self.assertEqual(line.strip(), "stderr")

        proc.stop(0)

    def test_cleanup(self):
        port_obj = TrivialMockPort()
        server_process = FakeServerProcess(port_obj=port_obj, name="test", cmd=["test"])
        server_process._start()
        server_process.stop()
        self.assertTrue(server_process.stdin.closed)
        self.assertTrue(server_process.stdout.closed)
        self.assertTrue(server_process.stderr.closed)

    def test_broken_pipe(self):
        port_obj = TrivialMockPort()

        port_obj.host.platform.os_name = 'win'
        server_process = FakeServerProcess(port_obj=port_obj, name="test", cmd=["test"])
        server_process.write("should break")
        self.assertTrue(server_process.has_crashed())
        self.assertIsNotNone(server_process.pid())
        self.assertIsNone(server_process._proc)
        self.assertEqual(server_process.broken_pipes, [server_process.stdin])

        port_obj.host.platform.os_name = 'mac'
        server_process = FakeServerProcess(port_obj=port_obj, name="test", cmd=["test"])
        server_process.write("should break")
        self.assertTrue(server_process.has_crashed())
        self.assertIsNone(server_process._proc)
        self.assertEqual(server_process.broken_pipes, [server_process.stdin])


class TestQuoteData(unittest.TestCase):
    def test_plain(self):
        qd = server_process.quote_data
        self.assertEqual(qd("foo"), ["foo"])

    def test_trailing_spaces(self):
        qd = server_process.quote_data
        self.assertEqual(qd("foo  "),
                         ["foo\x20\x20"])

    def test_newlines(self):
        qd = server_process.quote_data
        self.assertEqual(qd("foo \nbar\n"),
                         ["foo\x20\\n", "bar\\n"])

    def test_binary_data(self):
        qd = server_process.quote_data
        self.assertEqual(qd("\x00\x01ab"),
                         ["\\x00\\x01ab"])
