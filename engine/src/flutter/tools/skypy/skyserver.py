# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import socket
import subprocess
import logging
import os.path

class SkyServer(object):
    def __init__(self, paths, port, configuration, root):
        self.paths = paths
        self.port = port
        self.configuration = configuration
        self.root = root
        self.server = None

    @staticmethod
    def _port_in_use(port):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        return sock.connect_ex(('localhost', port)) == 0

    @staticmethod
    def _download_server_if_necessary(paths):
        subprocess.call(os.path.join(paths.sky_tools_directory,
            'download_sky_server'))
        return os.path.join(paths.src_root, 'out', 'downloads', 'sky_server')

    def __enter__(self):
        if self._port_in_use(self.port):
            logging.warn(
                'Port %s already in use, assuming custom sky_server started.' %
                self.port)
            return

        server_path = self._download_server_if_necessary(self.paths)
        server_command = [
            server_path,
            '-t', self.configuration,
            self.root,
            str(self.port),
        ]
        self.server = subprocess.Popen(server_command)

    def __exit__(self, exc_type, exc_value, traceback):
        if self.server:
            self.server.terminate()

    def path_as_url(self, path):
        return self.url_for_path(self.port, self.root, path)

    @staticmethod
    def url_for_path(port, root, path):
        relative_path = os.path.relpath(path, root)
        return 'http://localhost:%s/%s' % (port, relative_path)
