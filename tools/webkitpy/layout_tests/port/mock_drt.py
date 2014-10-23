# Copyright (c) 2012 Google Inc. All rights reserved.
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

"""
This is an implementation of the Port interface that overrides other
ports and changes the Driver binary to "MockDRT".

The MockDRT objects emulate what a real DRT would do. In particular, they
return the output a real DRT would return for a given test, assuming that
test actually passes (except for reftests, which currently cause the
MockDRT to crash).
"""

import base64
import logging
import optparse
import os
import sys
import types

# Since we execute this script directly as part of the unit tests, we need to ensure
# that Tools/Scripts is in sys.path for the next imports to work correctly.
script_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
if script_dir not in sys.path:
    sys.path.append(script_dir)

from webkitpy.common import read_checksum_from_png
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.layout_tests.port.driver import DriverInput, DriverOutput
from webkitpy.layout_tests.port.factory import PortFactory

_log = logging.getLogger(__name__)


class MockDRTPort(object):
    port_name = 'mock'

    @classmethod
    def determine_full_port_name(cls, host, options, port_name):
        return port_name

    def __init__(self, host, port_name, **kwargs):
        self.__delegate = PortFactory(host).get(port_name.replace('mock-', ''), **kwargs)
        self.__delegate_driver_class = self.__delegate._driver_class
        self.__delegate._driver_class = types.MethodType(self._driver_class, self.__delegate)

    def __getattr__(self, name):
        return getattr(self.__delegate, name)

    def check_build(self, needs_http, printer):
        return True

    def check_sys_deps(self, needs_http):
        return True

    def _driver_class(self, delegate):
        return self._mocked_driver_maker

    def _mocked_driver_maker(self, port, worker_number, pixel_tests, no_timeout=False):
        path_to_this_file = self.host.filesystem.abspath(__file__.replace('.pyc', '.py'))
        driver = self.__delegate_driver_class()(self, worker_number, pixel_tests, no_timeout)
        driver.cmd_line = self._overriding_cmd_line(driver.cmd_line,
                                                    self.__delegate._path_to_driver(),
                                                    sys.executable,
                                                    path_to_this_file,
                                                    self.__delegate.name())
        return driver

    @staticmethod
    def _overriding_cmd_line(original_cmd_line, driver_path, python_exe, this_file, port_name):
        def new_cmd_line(pixel_tests, per_test_args):
            cmd_line = original_cmd_line(pixel_tests, per_test_args)
            index = cmd_line.index(driver_path)
            cmd_line[index:index + 1] = [python_exe, this_file, '--platform', port_name]
            return cmd_line

        return new_cmd_line

    def start_helper(self):
        pass

    def start_http_server(self, additional_dirs, number_of_servers):
        pass

    def start_websocket_server(self):
        pass

    def acquire_http_lock(self):
        pass

    def stop_helper(self):
        pass

    def stop_http_server(self):
        pass

    def stop_websocket_server(self):
        pass

    def release_http_lock(self):
        pass

    def _make_wdiff_available(self):
        self.__delegate._wdiff_available = True

    def setup_environ_for_server(self, server_name):
        env = self.__delegate.setup_environ_for_server()
        # We need to propagate PATH down so the python code can find the checkout.
        env['PATH'] = os.environ['PATH']
        return env

    def lookup_virtual_test_args(self, test_name):
        suite = self.__delegate.lookup_virtual_suite(test_name)
        return suite.args + ['--virtual-test-suite-name', suite.name, '--virtual-test-suite-base', suite.base]

def main(argv, host, stdin, stdout, stderr):
    """Run the tests."""

    options, args = parse_options(argv)
    drt = MockDRT(options, args, host, stdin, stdout, stderr)
    return drt.run()


def parse_options(argv):
    # We do custom arg parsing instead of using the optparse module
    # because we don't want to have to list every command line flag DRT
    # accepts, and optparse complains about unrecognized flags.

    def get_arg(arg_name):
        if arg_name in argv:
            index = argv.index(arg_name)
            return argv[index + 1]
        return None

    options = optparse.Values({
        'actual_directory':        get_arg('--actual-directory'),
        'platform':                get_arg('--platform'),
        'virtual_test_suite_base': get_arg('--virtual-test-suite-base'),
        'virtual_test_suite_name': get_arg('--virtual-test-suite-name'),
    })
    return (options, argv)


class MockDRT(object):
    def __init__(self, options, args, host, stdin, stdout, stderr):
        self._options = options
        self._args = args
        self._host = host
        self._stdout = stdout
        self._stdin = stdin
        self._stderr = stderr

        port_name = None
        if options.platform:
            port_name = options.platform
        self._port = PortFactory(host).get(port_name=port_name, options=options)
        self._driver = self._port.create_driver(0)

    def run(self):
        while True:
            line = self._stdin.readline()
            if not line:
                return 0
            driver_input = self.input_from_line(line)
            dirname, basename = self._port.split_test(driver_input.test_name)
            is_reftest = (self._port.reference_files(driver_input.test_name) or
                          self._port.is_reference_html_file(self._port._filesystem, dirname, basename))
            output = self.output_for_test(driver_input, is_reftest)
            self.write_test_output(driver_input, output, is_reftest)

    def input_from_line(self, line):
        vals = line.strip().split("'")
        uri = vals[0]
        checksum = None
        should_run_pixel_tests = False
        if len(vals) == 2 and vals[1] == '--pixel-test':
            should_run_pixel_tests = True
        elif len(vals) == 3 and vals[1] == '--pixel-test':
            should_run_pixel_tests = True
            checksum = vals[2]
        elif len(vals) != 1:
            raise NotImplementedError

        if uri.startswith('http://') or uri.startswith('https://'):
            test_name = self._driver.uri_to_test(uri)
        else:
            test_name = self._port.relative_test_filename(uri)

        return DriverInput(test_name, 0, checksum, should_run_pixel_tests, args=[])

    def output_for_test(self, test_input, is_reftest):
        port = self._port
        if self._options.virtual_test_suite_name:
            test_input.test_name = test_input.test_name.replace(self._options.virtual_test_suite_base, self._options.virtual_test_suite_name)
        actual_text = port.expected_text(test_input.test_name)
        actual_audio = port.expected_audio(test_input.test_name)
        actual_image = None
        actual_checksum = None
        if is_reftest:
            # Make up some output for reftests.
            actual_text = 'reference text\n'
            actual_checksum = 'mock-checksum'
            actual_image = 'blank'
            if test_input.test_name.endswith('-mismatch.html'):
                actual_text = 'not reference text\n'
                actual_checksum = 'not-mock-checksum'
                actual_image = 'not blank'
        elif test_input.should_run_pixel_test and test_input.image_hash:
            actual_checksum = port.expected_checksum(test_input.test_name)
            actual_image = port.expected_image(test_input.test_name)

        if self._options.actual_directory:
            actual_path = port._filesystem.join(self._options.actual_directory, test_input.test_name)
            root, _ = port._filesystem.splitext(actual_path)
            text_path = root + '-actual.txt'
            if port._filesystem.exists(text_path):
                actual_text = port._filesystem.read_binary_file(text_path)
            audio_path = root + '-actual.wav'
            if port._filesystem.exists(audio_path):
                actual_audio = port._filesystem.read_binary_file(audio_path)
            image_path = root + '-actual.png'
            if port._filesystem.exists(image_path):
                actual_image = port._filesystem.read_binary_file(image_path)
                with port._filesystem.open_binary_file_for_reading(image_path) as filehandle:
                    actual_checksum = read_checksum_from_png.read_checksum(filehandle)

        return DriverOutput(actual_text, actual_image, actual_checksum, actual_audio)

    def write_test_output(self, test_input, output, is_reftest):
        if output.audio:
            self._stdout.write('Content-Type: audio/wav\n')
            self._stdout.write('Content-Transfer-Encoding: base64\n')
            self._stdout.write(base64.b64encode(output.audio))
            self._stdout.write('\n')
        else:
            self._stdout.write('Content-Type: text/plain\n')
            # FIXME: Note that we don't ensure there is a trailing newline!
            # This mirrors actual (Mac) DRT behavior but is a bug.
            if output.text:
                self._stdout.write(output.text)

        self._stdout.write('#EOF\n')

        if test_input.should_run_pixel_test and output.image_hash:
            self._stdout.write('\n')
            self._stdout.write('ActualHash: %s\n' % output.image_hash)
            self._stdout.write('ExpectedHash: %s\n' % test_input.image_hash)
            if output.image_hash != test_input.image_hash:
                self._stdout.write('Content-Type: image/png\n')
                self._stdout.write('Content-Length: %s\n' % len(output.image))
                self._stdout.write(output.image)
        self._stdout.write('#EOF\n')
        self._stdout.flush()
        self._stderr.write('#EOF\n')
        self._stderr.flush()


if __name__ == '__main__':
    # Note that the Mock in MockDRT refers to the fact that it is emulating a
    # real DRT, and as such, it needs access to a real SystemHost, not a MockSystemHost.
    sys.exit(main(sys.argv[1:], SystemHost(), sys.stdin, sys.stdout, sys.stderr))
