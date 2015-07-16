# Copyright (C) 2012 Google Inc. All rights reserved.
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
from webkitpy.layout_tests.port import test
from webkitpy.layout_tests.servers.server_base import ServerBase


class TestServerBase(unittest.TestCase):
    def test_corrupt_pid_file(self):
        # This tests that if the pid file is corrupt or invalid,
        # both start() and stop() deal with it correctly and delete the file.
        host = MockHost()
        test_port = test.TestPort(host)

        server = ServerBase(test_port, test_port.default_results_directory())
        server._pid_file = '/tmp/pidfile'
        server._spawn_process = lambda: 4
        server._is_server_running_on_all_ports = lambda: True

        host.filesystem.write_text_file(server._pid_file, 'foo')
        server.stop()
        self.assertEqual(host.filesystem.files[server._pid_file], None)

        host.filesystem.write_text_file(server._pid_file, 'foo')
        server.start()
        self.assertEqual(server._pid, 4)

        # Note that the pid file would not be None if _spawn_process()
        # was actually a real implementation.
        self.assertEqual(host.filesystem.files[server._pid_file], None)
