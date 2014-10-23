# Copyright (C) 2011 Google Inc. All rights reserved.
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

"""A class to help start/stop the PyWebSocket server as used by the layout tests."""

import logging
import os
import sys
import time

from webkitpy.layout_tests.servers import server_base
from webkitpy.thirdparty import mod_pywebsocket

_log = logging.getLogger(__name__)


_WS_LOG_PREFIX = 'pywebsocket.ws.log-'

_DEFAULT_WS_PORT = 8880


class PyWebSocket(server_base.ServerBase):

    def __init__(self, port_obj, output_dir):
        super(PyWebSocket, self).__init__(port_obj, output_dir)
        self._name = 'pywebsocket'
        self._log_prefixes = (_WS_LOG_PREFIX,)
        self._mappings = [{'port': _DEFAULT_WS_PORT}]
        self._pid_file = self._filesystem.join(self._runtime_path, '%s.pid' % self._name)

        self._port = _DEFAULT_WS_PORT
        self._layout_tests = self._port_obj.layout_tests_dir()
        self._web_socket_tests = self._filesystem.join(self._layout_tests, 'http', 'tests', 'websocket')
        time_str = time.strftime('%d%b%Y-%H%M%S')
        log_file_name = _WS_LOG_PREFIX + time_str
        self._error_log = self._filesystem.join(self._output_dir, log_file_name + "-err.txt")
        pywebsocket_base = self._port_obj.path_from_webkit_base('Tools', 'Scripts', 'webkitpy', 'thirdparty')
        pywebsocket_script = self._filesystem.join(pywebsocket_base, 'mod_pywebsocket', 'standalone.py')

        self._start_cmd = [
            sys.executable, '-u', pywebsocket_script,
            '--server-host', 'localhost',
            '--port', str(self._port),
            '--document-root', self._web_socket_tests,
            '--scan-dir', self._web_socket_tests,
            '--cgi-paths', '/',
            '--log-file', self._error_log,
            '--websock-handlers-map-file', self._filesystem.join(self._web_socket_tests, 'handler_map.txt'),
            ]
        self._env = self._port_obj.setup_environ_for_server()
        self._env['PYTHONPATH'] = (pywebsocket_base + os.pathsep + self._env.get('PYTHONPATH', ''))
