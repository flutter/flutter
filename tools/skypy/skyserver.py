# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import socket
import subprocess
import logging
import os.path
import platform

SKYPY_PATH = os.path.dirname(os.path.abspath(__file__))
SKY_TOOLS_PATH = os.path.dirname(SKYPY_PATH)
SKYGO_PATH = os.path.join(SKY_TOOLS_PATH, 'skygo')
SKY_ROOT = os.path.dirname(SKY_TOOLS_PATH)
SRC_ROOT = os.path.dirname(SKY_ROOT)

class SkyServer(object):
    def __init__(self, port, configuration, root, package_root):
        self.port = port
        self.configuration = configuration
        self.root = root
        self.package_root = package_root
        self.server = None

    @staticmethod
    def _port_in_use(port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        return sock.connect_ex(('localhost', port)) == 0

    @staticmethod
    def sky_server_path():

        if platform.system() == 'Linux':
            platform_dir = 'linux64'
        elif platform.system() == 'Mac':
            platform_dir = 'mac'
        else:
            assert False, 'No sky_server binary for this platform?'

        return os.path.join(SKYGO_PATH, platform_dir, 'sky_server')

    def start(self):
        if self._port_in_use(self.port):
            logging.warn(
                'Port %s already in use, assuming custom sky_server started.' %
                self.port)
            return

        server_path = self.sky_server_path()
        server_command = [
            server_path,
            '-t', self.configuration,
            self.root,
            str(self.port),
            self.package_root,
        ]
        self.server = subprocess.Popen(server_command)
        return self.server.pid

    def stop(self):
        if self.server:
            self.server.terminate()

    def __enter__(self):
        self.start()

    def __exit__(self, exc_type, exc_value, traceback):
        self.stop()

    def path_as_url(self, path):
        return self.url_for_path(self.port, self.root, path)

    @staticmethod
    def url_for_path(port, root, path):
        relative_path = os.path.relpath(path, root)
        return 'http://localhost:%s/%s' % (port, relative_path)
