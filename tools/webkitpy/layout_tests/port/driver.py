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
#     * Neither the Google name nor the names of its
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

import base64
import copy
import logging
import re
import shlex
import sys
import time
import os

from webkitpy.common.system import path
from webkitpy.common.system.profiler import ProfilerFactory


_log = logging.getLogger(__name__)


DRIVER_START_TIMEOUT_SECS = 30


class DriverInput(object):
    def __init__(self, test_name, timeout, image_hash, should_run_pixel_test, args):
        self.test_name = test_name
        self.timeout = timeout  # in ms
        self.image_hash = image_hash
        self.should_run_pixel_test = should_run_pixel_test
        self.args = args


class DriverOutput(object):
    """Groups information about a output from driver for easy passing
    and post-processing of data."""

    def __init__(self, text, image, image_hash, audio, crash=False,
            test_time=0, measurements=None, timeout=False, error='', crashed_process_name='??',
            crashed_pid=None, crash_log=None, leak=False, leak_log=None, pid=None):
        # FIXME: Args could be renamed to better clarify what they do.
        self.text = text
        self.image = image  # May be empty-string if the test crashes.
        self.image_hash = image_hash
        self.image_diff = None  # image_diff gets filled in after construction.
        self.audio = audio  # Binary format is port-dependent.
        self.crash = crash
        self.crashed_process_name = crashed_process_name
        self.crashed_pid = crashed_pid
        self.crash_log = crash_log
        self.leak = leak
        self.leak_log = leak_log
        self.test_time = test_time
        self.measurements = measurements
        self.timeout = timeout
        self.error = error  # stderr output
        self.pid = pid

    def has_stderr(self):
        return bool(self.error)


class DeviceFailure(Exception):
    pass


class Driver(object):
    """object for running test(s) using content_shell or other driver."""

    def __init__(self, port, worker_number, pixel_tests, no_timeout=False):
        """Initialize a Driver to subsequently run tests.

        Typically this routine will spawn content_shell in a config
        ready for subsequent input.

        port - reference back to the port object.
        worker_number - identifier for a particular worker/driver instance
        """
        self._port = port
        self._worker_number = worker_number
        self._no_timeout = no_timeout

        self._driver_tempdir = None
        # content_shell can report back subprocess crashes by printing
        # "#CRASHED - PROCESSNAME".  Since those can happen at any time
        # and ServerProcess won't be aware of them (since the actual tool
        # didn't crash, just a subprocess) we record the crashed subprocess name here.
        self._crashed_process_name = None
        self._crashed_pid = None

        # content_shell can report back subprocesses that became unresponsive
        # This could mean they crashed.
        self._subprocess_was_unresponsive = False

        # content_shell can report back subprocess DOM-object leaks by printing
        # "#LEAK". This leak detection is enabled only when the flag
        # --enable-leak-detection is passed to content_shell.
        self._leaked = False

        # stderr reading is scoped on a per-test (not per-block) basis, so we store the accumulated
        # stderr output, as well as if we've seen #EOF on this driver instance.
        # FIXME: We should probably remove _read_first_block and _read_optional_image_block and
        # instead scope these locally in run_test.
        self.error_from_test = str()
        self.err_seen_eof = False
        self._server_process = None
        self._current_cmd_line = None

        self._measurements = {}
        if self._port.get_option("profile"):
            profiler_name = self._port.get_option("profiler")
            self._profiler = ProfilerFactory.create_profiler(self._port.host,
                self._port._path_to_driver(), self._port.results_directory(), profiler_name)
        else:
            self._profiler = None

    def __del__(self):
        self.stop()

    def run_test(self, driver_input, stop_when_done):
        """Run a single test and return the results.

        Note that it is okay if a test times out or crashes and leaves
        the driver in an indeterminate state. The upper layers of the program
        are responsible for cleaning up and ensuring things are okay.

        Returns a DriverOutput object.
        """
        start_time = time.time()
        stdin_deadline = start_time + int(driver_input.timeout) / 2000.0
        self.start(driver_input.should_run_pixel_test, driver_input.args, stdin_deadline)
        test_begin_time = time.time()
        self.error_from_test = str()
        self.err_seen_eof = False

        command = self._command_from_driver_input(driver_input)
        deadline = test_begin_time + int(driver_input.timeout) / 1000.0

        self._server_process.write(command)
        text, audio = self._read_first_block(deadline)  # First block is either text or audio
        image, actual_image_hash = self._read_optional_image_block(deadline)  # The second (optional) block is image data.

        crashed = self.has_crashed()
        timed_out = self._server_process.timed_out
        pid = self._server_process.pid()
        leaked = self._leaked

        if not crashed:
            sanitizer = self._port._output_contains_sanitizer_messages(self.error_from_test)
            if sanitizer:
                self.error_from_test = 'OUTPUT CONTAINS "' + sanitizer + '", so we are treating this test as if it crashed, even though it did not.\n\n' + self.error_from_test
                crashed = True
                self._crashed_process_name = "unknown process name"
                self._crashed_pid = 0

        if stop_when_done or crashed or timed_out or leaked:
            # We call stop() even if we crashed or timed out in order to get any remaining stdout/stderr output.
            # In the timeout case, we kill the hung process as well.
            out, err = self._server_process.stop(self._port.driver_stop_timeout() if stop_when_done else 0.0)
            if out:
                text += out
            if err:
                self.error_from_test += err
            self._server_process = None

        crash_log = None
        if crashed:
            self.error_from_test, crash_log = self._get_crash_log(text, self.error_from_test, newer_than=start_time)

            # If we don't find a crash log use a placeholder error message instead.
            if not crash_log:
                pid_str = str(self._crashed_pid) if self._crashed_pid else "unknown pid"
                crash_log = 'No crash log found for %s:%s.\n' % (self._crashed_process_name, pid_str)
                # If we were unresponsive append a message informing there may not have been a crash.
                if self._subprocess_was_unresponsive:
                    crash_log += 'Process failed to become responsive before timing out.\n'

                # Print stdout and stderr to the placeholder crash log; we want as much context as possible.
                if self.error_from_test:
                    crash_log += '\nstdout:\n%s\nstderr:\n%s\n' % (text, self.error_from_test)

        return DriverOutput(text, image, actual_image_hash, audio,
            crash=crashed, test_time=time.time() - test_begin_time, measurements=self._measurements,
            timeout=timed_out, error=self.error_from_test,
            crashed_process_name=self._crashed_process_name,
            crashed_pid=self._crashed_pid, crash_log=crash_log,
            leak=leaked, leak_log=self._leak_log,
            pid=pid)

    def _get_crash_log(self, stdout, stderr, newer_than):
        return self._port._get_crash_log(self._crashed_process_name, self._crashed_pid, stdout, stderr, newer_than)

    # FIXME: Seems this could just be inlined into callers.
    @classmethod
    def _command_wrapper(cls, wrapper_option):
        # Hook for injecting valgrind or other runtime instrumentation,
        # used by e.g. tools/valgrind/valgrind_tests.py.
        return shlex.split(wrapper_option) if wrapper_option else []

    def is_http_test(self, test_name):
        return True

    def test_to_uri(self, test_name):
        """Convert a test name to a URI.

        Tests which have an 'https' directory in their paths (e.g.
        '/http/tests/security/mixedContent/https/test1.html') will be loaded
        over HTTPS; all other tests over HTTP.
        """
        assert self.is_http_test(test_name)
        return "http://127.0.0.1:8000/sky/tests/" + test_name

    def uri_to_test(self, uri):
        """Return the base layout test name for a given URI.

        This returns the test name for a given URI, e.g., if you passed in
        "file:///src/tests/fast/html/keygen.html" it would return
        "fast/html/keygen.html".

        """
        if uri.startswith("file:///"):
            prefix = path.abspath_to_uri(self._port.host.platform, self._port.layout_tests_dir())
            if not prefix.endswith('/'):
                prefix += '/'
            return uri[len(prefix):]
        if uri.startswith("http://"):
            return uri.replace('http://127.0.0.1:8000/', '')
        if uri.startswith("https://"):
            return uri.replace('https://127.0.0.1:8443/', '')
        raise NotImplementedError('unknown url type: %s' % uri)

    def has_crashed(self):
        if self._server_process is None:
            return False
        if self._crashed_process_name:
            return True
        if self._server_process.has_crashed():
            self._crashed_process_name = self._server_process.name()
            self._crashed_pid = self._server_process.pid()
            return True
        return False

    def start(self, pixel_tests, per_test_args, deadline):
        new_cmd_line = self.cmd_line(pixel_tests, per_test_args)
        if not self._server_process or new_cmd_line != self._current_cmd_line:
            self._start(pixel_tests, per_test_args)
            self._run_post_start_tasks()

    def _setup_environ_for_driver(self, environment):
        if self._profiler:
            environment = self._profiler.adjusted_environment(environment)
        return environment

    def _start(self, pixel_tests, per_test_args, wait_for_ready=True):
        self.stop()
        self._driver_tempdir = self._port._filesystem.mkdtemp(prefix='%s-' % self._port.driver_name())
        server_name = self._port.driver_name()
        environment = self._port.setup_environ_for_server(server_name)
        environment = self._setup_environ_for_driver(environment)
        self._crashed_process_name = None
        self._crashed_pid = None
        self._leaked = False
        self._leak_log = None
        cmd_line = self.cmd_line(pixel_tests, per_test_args)
        self._server_process = self._port._server_process_constructor(self._port, server_name, cmd_line, environment, logging=self._port.get_option("driver_logging"))
        self._server_process.start()
        self._current_cmd_line = cmd_line

        if wait_for_ready:
            deadline = time.time() + DRIVER_START_TIMEOUT_SECS
            if not self._wait_for_server_process_output(self._server_process, deadline, '#READY'):
                _log.error("content_shell took too long to startup.")

    def _wait_for_server_process_output(self, server_process, deadline, text):
        output = ''
        line = server_process.read_stdout_line(deadline)
        while not server_process.timed_out and not server_process.has_crashed() and not text in line.rstrip():
            output += line
            line = server_process.read_stdout_line(deadline)

        if server_process.timed_out or server_process.has_crashed():
            _log.error('Failed to start the %s process: \n%s' % (server_process.name(), output))
            return False

        return True

    def _run_post_start_tasks(self):
        # Remote drivers may override this to delay post-start tasks until the server has ack'd.
        if self._profiler:
            self._profiler.attach_to_pid(self._pid_on_target())

    def _pid_on_target(self):
        # Remote drivers will override this method to return the pid on the device.
        return self._server_process.pid()

    def stop(self, timeout_secs=0.0):
        if self._server_process:
            self._server_process.stop(timeout_secs)
            self._server_process = None
            if self._profiler:
                self._profiler.profile_after_exit()

        if self._driver_tempdir:
            self._port._filesystem.rmtree(str(self._driver_tempdir))
            self._driver_tempdir = None

        self._current_cmd_line = None

    def cmd_line(self, pixel_tests, per_test_args):
        cmd = self._command_wrapper(self._port.get_option('wrapper'))
        cmd.append(self._port._path_to_driver())
        if self._no_timeout:
            cmd.append('--no-timeout')
        cmd.extend(self._port.get_option('additional_drt_flag', []))
        cmd.extend(self._port.additional_drt_flag())
        if self._port.get_option('enable_leak_detection'):
            cmd.append('--enable-leak-detection')
        cmd.extend(per_test_args)
        return cmd

    def _check_for_driver_crash(self, error_line):
        if error_line == "#CRASHED\n":
            # This is used on Windows to report that the process has crashed
            # See http://trac.webkit.org/changeset/65537.
            self._crashed_process_name = self._server_process.name()
            self._crashed_pid = self._server_process.pid()
        elif (error_line.startswith("#CRASHED - ")
            or error_line.startswith("#PROCESS UNRESPONSIVE - ")):
            # WebKitTestRunner uses this to report that the WebProcess subprocess crashed.
            match = re.match('#(?:CRASHED|PROCESS UNRESPONSIVE) - (\S+)', error_line)
            self._crashed_process_name = match.group(1) if match else 'WebProcess'
            match = re.search('pid (\d+)', error_line)
            pid = int(match.group(1)) if match else None
            self._crashed_pid = pid
            # FIXME: delete this after we're sure this code is working :)
            _log.debug('%s crash, pid = %s, error_line = %s' % (self._crashed_process_name, str(pid), error_line))
            if error_line.startswith("#PROCESS UNRESPONSIVE - "):
                self._subprocess_was_unresponsive = True
                self._port.sample_process(self._crashed_process_name, self._crashed_pid)
                # We want to show this since it's not a regular crash and probably we don't have a crash log.
                self.error_from_test += error_line
            return True
        return self.has_crashed()

    def _check_for_leak(self, error_line):
        if error_line.startswith("#LEAK - "):
            self._leaked = True
            match = re.match('#LEAK - (\S+) pid (\d+) (.+)\n', error_line)
            self._leak_log = match.group(3)
        return self._leaked

    def _command_from_driver_input(self, driver_input):
        # FIXME: performance tests pass in full URLs instead of test names.
        if driver_input.test_name.startswith('http://') or driver_input.test_name.startswith('https://')  or driver_input.test_name == ('about:blank'):
            command = driver_input.test_name
        elif self.is_http_test(driver_input.test_name):
            command = self.test_to_uri(driver_input.test_name)
        else:
            command = self._port.abspath_for_test(driver_input.test_name)
            if sys.platform == 'cygwin':
                command = path.cygpath(command)

        assert not driver_input.image_hash or driver_input.should_run_pixel_test

        # ' is the separator between arguments.
        if self._port.supports_per_test_timeout():
            command += "'--timeout'%s" % driver_input.timeout
        if driver_input.should_run_pixel_test:
            command += "'--pixel-test"
        if driver_input.image_hash:
            command += "'" + driver_input.image_hash
        return command + "\n"

    def _read_first_block(self, deadline):
        # returns (text_content, audio_content)
        block = self._read_block(deadline, is_first_block=True)
        if block.malloc:
            self._measurements['Malloc'] = float(block.malloc)
        if block.js_heap:
            self._measurements['JSHeap'] = float(block.js_heap)
        if block.content_type == 'audio/wav':
            return (None, block.decoded_content)
        return (block.decoded_content, None)

    def _read_optional_image_block(self, deadline):
        # returns (image, actual_image_hash)
        block = self._read_block(deadline, wait_for_stderr_eof=True)
        if block.content and block.content_type == 'image/png':
            return (block.decoded_content, block.content_hash)
        return (None, block.content_hash)

    def _read_header(self, block, line, header_text, header_attr, header_filter=None):
        if line.startswith(header_text) and getattr(block, header_attr) is None:
            value = line.split()[1]
            if header_filter:
                value = header_filter(value)
            setattr(block, header_attr, value)
            return True
        return False

    def _process_stdout_line(self, block, line):
        if (self._read_header(block, line, 'Content-Type: ', 'content_type')
            or self._read_header(block, line, 'Content-Transfer-Encoding: ', 'encoding')
            or self._read_header(block, line, 'Content-Length: ', '_content_length', int)
            or self._read_header(block, line, 'ActualHash: ', 'content_hash')
            or self._read_header(block, line, 'DumpMalloc: ', 'malloc')
            or self._read_header(block, line, 'DumpJSHeap: ', 'js_heap')
            or self._read_header(block, line, 'StdinPath', 'stdin_path')):
            return
        # Note, we're not reading ExpectedHash: here, but we could.
        # If the line wasn't a header, we just append it to the content.
        block.content += line

    def _strip_eof(self, line):
        if line and line.endswith("#EOF\n"):
            return line[:-5], True
        if line and line.endswith("#EOF\r\n"):
            _log.error("Got a CRLF-terminated #EOF - this is a driver bug.")
            return line[:-6], True
        return line, False

    def _read_block(self, deadline, is_first_block=False, wait_for_stderr_eof=False):
        block = ContentBlock()
        out_seen_eof = False

        have_seen_begin = not is_first_block
        have_printed_stdout_limbo_line = False
        have_printed_stderr_limbo_line = False

        while not self.has_crashed():
            if out_seen_eof and (self.err_seen_eof or not wait_for_stderr_eof):
                break

            if self.err_seen_eof:
                out_line = self._server_process.read_stdout_line(deadline)
                err_line = None
            elif out_seen_eof:
                out_line = None
                err_line = self._server_process.read_stderr_line(deadline)
            else:
                out_line, err_line = self._server_process.read_either_stdout_or_stderr_line(deadline)

            if not have_seen_begin:
                # FIXME(sky): Instead of logging, this should cause the previous test to fail.
                if err_line:
                    if not have_printed_stdout_limbo_line:
                        have_printed_stdout_limbo_line = True
                        _log.error('\nSaw a stderr lines between the end of the previous test and the start of the current one:')
                    _log.error(err_line)
                if out_line:
                    if out_line == '#BEGIN\n':
                        have_seen_begin = True
                        out_line = ''
                        block.content = ''
                    else:
                        if not have_printed_stdout_limbo_line:
                            have_printed_stdout_limbo_line = True
                            _log.error('\nSaw a stdout line between the end of the previous test and the start of the current one:')
                        _log.error(out_line)

            if self._server_process.timed_out or self.has_crashed():
                break

            if out_line:
                assert not out_seen_eof
                out_line, out_seen_eof = self._strip_eof(out_line)
            if err_line:
                assert not self.err_seen_eof
                err_line, self.err_seen_eof = self._strip_eof(err_line)

            if out_line:
                if out_line[-1] != "\n":
                    _log.error("Last character read from DRT stdout line was not a newline!  This indicates either a NRWT or DRT bug.")
                content_length_before_header_check = block._content_length
                self._process_stdout_line(block, out_line)
                # FIXME: Unlike HTTP, DRT dumps the content right after printing a Content-Length header.
                # Don't wait until we're done with headers, just read the binary blob right now.
                if content_length_before_header_check != block._content_length:
                    if block._content_length > 0:
                        block.content = self._server_process.read_stdout(deadline, block._content_length)
                    else:
                        _log.error("Received content of type %s with Content-Length of 0!  This indicates a bug in %s.",
                                   block.content_type, self._server_process.name())

            if err_line:
                if self._check_for_driver_crash(err_line):
                    break
                if self._check_for_leak(err_line):
                    break
                self.error_from_test += err_line

        block.decode_content()
        return block


class ContentBlock(object):
    def __init__(self):
        self.content_type = None
        self.encoding = None
        self.content_hash = None
        self._content_length = None
        # Content is treated as binary data even though the text output is usually UTF-8.
        self.content = str()  # FIXME: Should be bytearray() once we require Python 2.6.
        self.decoded_content = None
        self.malloc = None
        self.js_heap = None
        self.stdin_path = None

    def decode_content(self):
        if self.encoding == 'base64' and self.content is not None:
            self.decoded_content = base64.b64decode(self.content)
        else:
            self.decoded_content = self.content
