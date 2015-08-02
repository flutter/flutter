# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import socket
import subprocess
import logging
import os.path

SKYPY_PATH = os.path.dirname(os.path.abspath(__file__))
SRC_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(SKYPY_PATH)))

WORKBENCH_ROOT = os.path.join(SRC_ROOT, 'sky', 'packages', 'workbench')
DART_SDK = os.path.join(SRC_ROOT, 'third_party', 'dart-sdk', 'dart-sdk', 'bin')
PUB = os.path.join(DART_SDK, 'pub')
PUB_CACHE = os.path.join(SRC_ROOT, "dart-pub-cache")

class SkyServer(object):
    def __init__(self, port, root, package_root):
        self.port = port
        self.root = root
        self.package_root = package_root
        self.server = None

    @staticmethod
    def _port_in_use(port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        return sock.connect_ex(('localhost', port)) == 0

    def start(self):
        if self._port_in_use(self.port):
            logging.warn(
                'Port %s already in use, assuming custom sky_server started.' %
                self.port)
            return

        env = os.environ.copy()
        env["PUB_CACHE"] = PUB_CACHE
        args = [PUB, 'run', 'sky_tools:sky_server', str(self.port)]
        self.server = subprocess.Popen(args, cwd=WORKBENCH_ROOT, env=env)
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
