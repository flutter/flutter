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

"""Base class used to start servers used by the layout tests."""

import errno
import logging
import socket
import tempfile
import time


_log = logging.getLogger(__name__)


class ServerError(Exception):
    pass


class ServerBase(object):
    """A skeleton class for starting and stopping servers used by the layout tests."""

    def __init__(self, port_obj, output_dir):
        self._port_obj = port_obj
        self._executive = port_obj._executive
        self._filesystem = port_obj._filesystem
        self._platform = port_obj.host.platform
        self._output_dir = output_dir

        # We need a non-checkout-dependent place to put lock files, etc. We
        # don't use the Python default on the Mac because it defaults to a
        # randomly-generated directory under /var/folders and no one would ever
        # look there.
        tmpdir = tempfile.gettempdir()
        if self._platform.is_mac():
            tmpdir = '/tmp'

        self._runtime_path = self._filesystem.join(tmpdir, "WebKit")
        self._filesystem.maybe_make_directory(self._runtime_path)

        # Subclasses must override these fields.
        self._name = '<virtual>'
        self._log_prefixes = tuple()
        self._mappings = {}
        self._pid_file = None
        self._start_cmd = None

        # Subclasses may override these fields.
        self._env = None
        self._stdout = self._executive.PIPE
        self._stderr = self._executive.PIPE
        self._process = None
        self._pid = None
        self._error_log_path = None

    def start(self):
        """Starts the server. It is an error to start an already started server.

        This method also stops any stale servers started by a previous instance."""
        assert not self._pid, '%s server is already running' % self._name

        # Stop any stale servers left over from previous instances.
        if self._filesystem.exists(self._pid_file):
            try:
                self._pid = int(self._filesystem.read_text_file(self._pid_file))
                _log.debug('stale %s pid file, pid %d' % (self._name, self._pid))
                self._stop_running_server()
            except (ValueError, UnicodeDecodeError):
                # These could be raised if the pid file is corrupt.
                self._remove_pid_file()
            self._pid = None

        self._remove_stale_logs()
        self._prepare_config()
        self._check_that_all_ports_are_available()

        self._pid = self._spawn_process()

        if self._wait_for_action(self._is_server_running_on_all_ports):
            _log.debug("%s successfully started (pid = %d)" % (self._name, self._pid))
        else:
            self._log_errors_from_subprocess()
            self._stop_running_server()
            raise ServerError('Failed to start %s server' % self._name)

    def stop(self):
        """Stops the server. Stopping a server that isn't started is harmless."""
        actual_pid = None
        try:
            if self._filesystem.exists(self._pid_file):
                try:
                    actual_pid = int(self._filesystem.read_text_file(self._pid_file))
                except (ValueError, UnicodeDecodeError):
                    # These could be raised if the pid file is corrupt.
                    pass
                if not self._pid:
                    self._pid = actual_pid

            if not self._pid:
                return

            if not actual_pid:
                _log.warning('Failed to stop %s: pid file is missing' % self._name)
                return
            if self._pid != actual_pid:
                _log.warning('Failed to stop %s: pid file contains %d, not %d' %
                            (self._name, actual_pid, self._pid))
                # Try to kill the existing pid, anyway, in case it got orphaned.
                self._executive.kill_process(self._pid)
                self._pid = None
                return

            _log.debug("Attempting to shut down %s server at pid %d" % (self._name, self._pid))
            self._stop_running_server()
            _log.debug("%s server at pid %d stopped" % (self._name, self._pid))
            self._pid = None
        finally:
            # Make sure we delete the pid file no matter what happens.
            self._remove_pid_file()

    def _prepare_config(self):
        """This routine can be overridden by subclasses to do any sort
        of initialization required prior to starting the server that may fail."""
        pass

    def _remove_stale_logs(self):
        """This routine can be overridden by subclasses to try and remove logs
        left over from a prior run. This routine should log warnings if the
        files cannot be deleted, but should not fail unless failure to
        delete the logs will actually cause start() to fail."""
        # Sometimes logs are open in other processes but they should clear eventually.
        for log_prefix in self._log_prefixes:
            try:
                self._remove_log_files(self._output_dir, log_prefix)
            except OSError, e:
                _log.warning('Failed to remove old %s %s files' % (self._name, log_prefix))

    def _spawn_process(self):
        _log.debug('Starting %s server, cmd="%s"' % (self._name, self._start_cmd))
        process = self._executive.popen(self._start_cmd, env=self._env, stdout=self._stdout, stderr=self._stderr)
        pid = process.pid
        self._filesystem.write_text_file(self._pid_file, str(pid))
        return pid

    def _stop_running_server(self):
        self._wait_for_action(self._check_and_kill)
        if self._filesystem.exists(self._pid_file):
            self._filesystem.remove(self._pid_file)

    def _check_and_kill(self):
        if self._executive.check_running_pid(self._pid):
            _log.debug('pid %d is running, killing it' % self._pid)
            host = self._port_obj.host
            self._executive.kill_process(self._pid)
            return False
        else:
            _log.debug('pid %d is not running' % self._pid)

        return True

    def _remove_pid_file(self):
        if self._filesystem.exists(self._pid_file):
            self._filesystem.remove(self._pid_file)

    def _remove_log_files(self, folder, starts_with):
        files = self._filesystem.listdir(folder)
        for file in files:
            if file.startswith(starts_with):
                full_path = self._filesystem.join(folder, file)
                self._filesystem.remove(full_path)

    def _log_errors_from_subprocess(self):
        _log.error('logging %s errors, if any' % self._name)
        if self._process:
            _log.error('%s returncode %s' % (self._name, str(self._process.returncode)))
            if self._process.stderr:
                stderr_text = self._process.stderr.read()
                if stderr_text:
                    _log.error('%s stderr:' % self._name)
                    for line in stderr_text.splitlines():
                        _log.error('  %s' % line)
                else:
                    _log.error('%s no stderr' % self._name)
            else:
                _log.error('%s no stderr handle' % self._name)
        else:
            _log.error('%s no process' % self._name)
        if self._error_log_path and self._filesystem.exists(self._error_log_path):
            error_log_text = self._filesystem.read_text_file(self._error_log_path)
            if error_log_text:
                _log.error('%s error log (%s) contents:' % (self._name, self._error_log_path))
                for line in error_log_text.splitlines():
                    _log.error('  %s' % line)
            else:
                _log.error('%s error log empty' % self._name)
            _log.error('')
        else:
            _log.error('%s no error log' % self._name)

    def _wait_for_action(self, action, wait_secs=20.0, sleep_secs=1.0):
        """Repeat the action for wait_sec or until it succeeds, sleeping for sleep_secs
        in between each attempt. Returns whether it succeeded."""
        start_time = time.time()
        while time.time() - start_time < wait_secs:
            if action():
                return True
            _log.debug("Waiting for action: %s" % action)
            time.sleep(sleep_secs)

        return False

    def _is_server_running_on_all_ports(self):
        """Returns whether the server is running on all the desired ports."""

        # TODO(dpranke): crbug/378444 maybe pid is unreliable on win?
        if not self._platform.is_win() and not self._executive.check_running_pid(self._pid):
            _log.debug("Server isn't running at all")
            self._log_errors_from_subprocess()
            raise ServerError("Server exited")

        for mapping in self._mappings:
            s = socket.socket()
            port = mapping['port']
            try:
                s.connect(('localhost', port))
                _log.debug("Server running on %d" % port)
            except IOError, e:
                if e.errno not in (errno.ECONNREFUSED, errno.ECONNRESET):
                    raise
                _log.debug("Server NOT running on %d: %s" % (port, e))
                return False
            finally:
                s.close()
        return True

    def _check_that_all_ports_are_available(self):
        for mapping in self._mappings:
            s = socket.socket()
            if not self._platform.is_win():
                s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            port = mapping['port']
            try:
                s.bind(('localhost', port))
            except IOError, e:
                if e.errno in (errno.EALREADY, errno.EADDRINUSE):
                    raise ServerError('Port %d is already in use.' % port)
                elif self._platform.is_win() and e.errno in (errno.WSAEACCES,):  # pylint: disable=E1101
                    raise ServerError('Port %d is already in use.' % port)
                else:
                    raise
            finally:
                s.close()
        _log.debug('all ports are available')
