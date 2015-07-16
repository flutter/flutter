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

import re
import sys
import unittest

from webkitpy.common.system.executive_mock import MockExecutive
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.common.host_mock import MockHost
from webkitpy.layout_tests.port import test
from webkitpy.layout_tests.servers.apache_http import ApacheHTTP
from webkitpy.layout_tests.servers.server_base import ServerError


class TestApacheHTTP(unittest.TestCase):
    def test_start_cmd(self):
        # Fails on win - see https://bugs.webkit.org/show_bug.cgi?id=84726
        if sys.platform in ('cygwin', 'win32'):
            return

        def fake_pid(_):
            host.filesystem.write_text_file('/tmp/WebKit/httpd.pid', '42')
            return True

        host = MockHost()
        host.executive = MockExecutive(should_log=True)
        test_port = test.TestPort(host)
        host.filesystem.write_text_file(test_port.path_to_apache_config_file(), '')

        server = ApacheHTTP(test_port, "/mock/output_dir", additional_dirs=[], number_of_servers=4)
        server._check_that_all_ports_are_available = lambda: True
        server._is_server_running_on_all_ports = lambda: True
        server._wait_for_action = fake_pid
        oc = OutputCapture()
        try:
            oc.capture_output()
            server.start()
            server.stop()
        finally:
            _, _, logs = oc.restore_output()
        self.assertIn("StartServers 4", logs)
        self.assertIn("MinSpareServers 4", logs)
        self.assertIn("MaxSpareServers 4", logs)
