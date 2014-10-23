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

from webkitpy.common.system.systemhost_mock import MockSystemHost

from webkitpy.layout_tests.port import Port, Driver, DriverOutput
from webkitpy.layout_tests.port import browser_test, browser_test_driver
from webkitpy.layout_tests.port.server_process_mock import MockServerProcess

from webkitpy.layout_tests.port.port_testcase import TestWebKitPort

from webkitpy.tool.mocktool import MockOptions


class BrowserTestDriverTest(unittest.TestCase):
    def test_read_stdin_path(self):
        port = TestWebKitPort()
        driver = browser_test_driver.BrowserTestDriver(port, 0, pixel_tests=True)
        driver._server_process = MockServerProcess(lines=[
            'StdinPath: /foo/bar', '#EOF'])
        content_block = driver._read_block(0)
        self.assertEqual(content_block.stdin_path, '/foo/bar')
        driver._stdin_directory = None
