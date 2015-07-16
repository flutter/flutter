# Copyright (C) 2010 Google Inc. All rights reserved.
# Copyright (C) 2010 Gabor Rapcsanyi (rgabor@inf.u-szeged.hu), University of Szeged
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

"""Unit tests for manager.py."""

import sys
import time
import unittest

from webkitpy.common.host_mock import MockHost
from webkitpy.layout_tests.controllers.manager import Manager
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models.test_run_results import TestRunResults
from webkitpy.tool.mocktool import MockOptions


class FakePrinter(object):
    def write_update(self, s):
        pass


class ManagerTest(unittest.TestCase):
    def test_needs_servers(self):
        def get_manager():
            host = MockHost()
            port = host.port_factory.get('test-mac-leopard')
            manager = Manager(port, options=MockOptions(http=True, max_locked_shards=1), printer=FakePrinter())
            return manager

        manager = get_manager()
        self.assertFalse(manager.needs_servers(['fast/html']))

        manager = get_manager()
        self.assertTrue(manager.needs_servers(['http/tests/misc']))

    def test_servers_started(self):
        def get_manager(port):
            manager = Manager(port, options=MockOptions(http=True, max_locked_shards=1), printer=FakePrinter())
            return manager

        def start_http_server(additional_dirs, number_of_drivers):
            self.http_started = True

        def start_websocket_server():
            self.websocket_started = True

        def stop_http_server():
            self.http_stopped = True

        def stop_websocket_server():
            self.websocket_stopped = True

        host = MockHost()
        port = host.port_factory.get('test-mac-leopard')
        port.start_http_server = start_http_server
        port.start_websocket_server = start_websocket_server
        port.stop_http_server = stop_http_server
        port.stop_websocket_server = stop_websocket_server

        self.http_started = self.http_stopped = self.websocket_started = self.websocket_stopped = False
        manager = get_manager(port)
        manager._start_servers(['http/tests/foo.html'])
        self.assertEqual(self.http_started, True)
        self.assertEqual(self.websocket_started, False)
        manager._stop_servers()
        self.assertEqual(self.http_stopped, True)
        self.assertEqual(self.websocket_stopped, False)

        self.http_started = self.http_stopped = self.websocket_started = self.websocket_stopped = False
        manager._start_servers(['http/tests/websocket/foo.html'])
        self.assertEqual(self.http_started, True)
        self.assertEqual(self.websocket_started, True)
        manager._stop_servers()
        self.assertEqual(self.http_stopped, True)
        self.assertEqual(self.websocket_stopped, True)

        self.http_started = self.http_stopped = self.websocket_started = self.websocket_stopped = False
        manager._start_servers(['fast/html/foo.html'])
        self.assertEqual(self.http_started, False)
        self.assertEqual(self.websocket_started, False)
        manager._stop_servers()
        self.assertEqual(self.http_stopped, False)
        self.assertEqual(self.websocket_stopped, False)


    def test_look_for_new_crash_logs(self):
        def get_manager():
            host = MockHost()
            port = host.port_factory.get('test-mac-leopard')
            manager = Manager(port, options=MockOptions(test_list=None, http=True, max_locked_shards=1), printer=FakePrinter())
            return manager
        host = MockHost()
        port = host.port_factory.get('test-mac-leopard')
        tests = ['failures/expected/crash.html']
        expectations = test_expectations.TestExpectations(port, tests)
        run_results = TestRunResults(expectations, len(tests))
        manager = get_manager()
        manager._look_for_new_crash_logs(run_results, time.time())
