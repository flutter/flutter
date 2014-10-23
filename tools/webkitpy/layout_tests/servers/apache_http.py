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

"""Start and stop the Apache HTTP server as it is used by the layout tests."""

import logging
import os
import socket

from webkitpy.layout_tests.servers import server_base


_log = logging.getLogger(__name__)


class ApacheHTTP(server_base.ServerBase):
    def __init__(self, port_obj, output_dir, additional_dirs, number_of_servers):
        super(ApacheHTTP, self).__init__(port_obj, output_dir)
        # We use the name "httpd" instead of "apache" to make our paths (e.g. the pid file: /tmp/WebKit/httpd.pid)
        # match old-run-webkit-tests: https://bugs.webkit.org/show_bug.cgi?id=63956
        self._name = 'httpd'
        self._log_prefixes = ('access_log', 'error_log')
        self._mappings = [{'port': 8000},
                          {'port': 8080},
                          {'port': 8443, 'sslcert': True}]
        self._number_of_servers = number_of_servers

        self._pid_file = self._filesystem.join(self._runtime_path, '%s.pid' % self._name)

        executable = self._port_obj.path_to_apache()
        server_root = self._filesystem.dirname(self._filesystem.dirname(executable))

        test_dir = self._port_obj.layout_tests_dir()
        mojo_gen_dir = self._filesystem.join(
            self._filesystem.abspath(port_obj.gen_dir()), "mojo")
        js_test_resources_dir = self._filesystem.join(test_dir, "resources")
        media_resources_dir = self._filesystem.join(test_dir, "media")
        mime_types_path = self._filesystem.join(test_dir, "http", "conf", "mime.types")
        cert_file = self._filesystem.join(test_dir, "http", "conf", "webkit-httpd.pem")

        self._access_log_path = self._filesystem.join(output_dir, "access_log.txt")
        self._error_log_path = self._filesystem.join(output_dir, "error_log.txt")

        self._is_win = self._port_obj.host.platform.is_win()

        start_cmd = [executable,
            '-f', '%s' % self._port_obj.path_to_apache_config_file(),
            '-C', 'ServerRoot "%s"' % server_root,
            '-C', 'DocumentRoot "%s"' % test_dir,
            '-c', 'Alias /mojo "%s"' % mojo_gen_dir,
            '-c', 'Alias /js-test-resources "%s"' % js_test_resources_dir,
            '-c', 'Alias /media-resources "%s"' % media_resources_dir,
            '-c', 'TypesConfig "%s"' % mime_types_path,
            '-c', 'CustomLog "%s" common' % self._access_log_path,
            '-c', 'ErrorLog "%s"' % self._error_log_path,
            '-c', 'PidFile %s' % self._pid_file,
            '-c', 'SSLCertificateFile "%s"' % cert_file,
            ]

        if self._is_win:
            start_cmd += ['-c', "ThreadsPerChild %d" % (self._number_of_servers * 2)]
        else:
            start_cmd += ['-c', "StartServers %d" % self._number_of_servers,
                          '-c', "MinSpareServers %d" % self._number_of_servers,
                          '-c', "MaxSpareServers %d" % self._number_of_servers,
                          '-C', 'User "%s"' % os.environ.get('USERNAME', os.environ.get('USER', '')),
                          '-k', 'start']

        enable_ipv6 = self._port_obj.http_server_supports_ipv6()
        # Perform part of the checks Apache's APR does when trying to listen to
        # a specific host/port. This allows us to avoid trying to listen to
        # IPV6 addresses when it fails on Apache. APR itself tries to call
        # getaddrinfo() again without AI_ADDRCONFIG if the first call fails
        # with EBADFLAGS, but that is not how it normally fails in our use
        # cases, so ignore that for now.
        # See https://bugs.webkit.org/show_bug.cgi?id=98602#c7
        try:
            socket.getaddrinfo('::1', 0, 0, 0, 0, socket.AI_ADDRCONFIG)
        except:
            enable_ipv6 = False

        for mapping in self._mappings:
            port = mapping['port']

            start_cmd += ['-C', "Listen 127.0.0.1:%d" % port]

            # We listen to both IPv4 and IPv6 loop-back addresses, but ignore
            # requests to 8000 from random users on network.
            # See https://bugs.webkit.org/show_bug.cgi?id=37104
            if enable_ipv6:
                start_cmd += ['-C', "Listen [::1]:%d" % port]

        if additional_dirs:
            self._start_cmd = start_cmd
            for alias, path in additional_dirs.iteritems():
                start_cmd += ['-c', 'Alias %s "%s"' % (alias, path),
                        # Disable CGI handler for additional dirs.
                        '-c', '<Location %s>' % alias,
                        '-c', 'RemoveHandler .cgi .pl',
                        '-c', '</Location>']

        self._start_cmd = start_cmd

    def _spawn_process(self):
        _log.debug('Starting %s server, cmd="%s"' % (self._name, str(self._start_cmd)))
        self._process = self._executive.popen(self._start_cmd, stderr=self._executive.PIPE)
        if self._process.returncode is not None:
            retval = self._process.returncode
            err = self._process.stderr.read()
            if retval or len(err):
                raise server_base.ServerError('Failed to start %s: %s' % (self._name, err))

        # For some reason apache isn't guaranteed to have created the pid file before
        # the process exits, so we wait a little while longer.
        if not self._wait_for_action(lambda: self._filesystem.exists(self._pid_file)):
            self._log_errors_from_subprocess()
            raise server_base.ServerError('Failed to start %s: no pid file found' % self._name)

        return int(self._filesystem.read_text_file(self._pid_file))

    def stop(self):
        self._stop_running_server()

    def _stop_running_server(self):
        # If apache was forcefully killed, the pid file will not have been deleted, so check
        # that the process specified by the pid_file no longer exists before deleting the file.
        if self._pid and not self._executive.check_running_pid(self._pid):
            self._filesystem.remove(self._pid_file)
            return

        if self._is_win:
            self._executive.kill_process(self._pid)
            return

        proc = self._executive.popen([self._port_obj.path_to_apache(),
                                      '-f', self._port_obj.path_to_apache_config_file(),
                                      '-c', 'PidFile "%s"' % self._pid_file,
                                      '-k', 'stop'], stderr=self._executive.PIPE)
        proc.wait()
        retval = proc.returncode
        err = proc.stderr.read()
        if retval or len(err):
            raise server_base.ServerError('Failed to stop %s: %s' % (self._name, err))

        # For some reason apache isn't guaranteed to have actually stopped after
        # the stop command returns, so we wait a little while longer for the
        # pid file to be removed.
        if not self._wait_for_action(lambda: not self._filesystem.exists(self._pid_file)):
            raise server_base.ServerError('Failed to stop %s: pid file still exists' % self._name)
