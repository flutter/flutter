# Copyright (C) 2010 Google Inc. All rights reserved.
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

"""Unit testing base class for Port implementations."""

import errno
import logging
import os
import socket
import sys
import time
import unittest

from webkitpy.common.system.executive_mock import MockExecutive, MockExecutive2
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.common.system.systemhost_mock import MockSystemHost
from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.port.base import Port, TestConfiguration
from webkitpy.layout_tests.port.server_process_mock import MockServerProcess
from webkitpy.tool.mocktool import MockOptions


# FIXME: get rid of this fixture
class TestWebKitPort(Port):
    port_name = "testwebkitport"

    def __init__(self, port_name=None, symbols_string=None,
                 expectations_file=None, skips_file=None, host=None, config=None,
                 **kwargs):
        port_name = port_name or TestWebKitPort.port_name
        self.symbols_string = symbols_string  # Passing "" disables all staticly-detectable features.
        host = host or MockSystemHost()
        super(TestWebKitPort, self).__init__(host, port_name=port_name, **kwargs)

    def all_test_configurations(self):
        return [self.test_configuration()]

    def _symbols_string(self):
        return self.symbols_string

    def _tests_for_disabled_features(self):
        return ["accessibility", ]


class FakePrinter(object):
    def write_update(self, msg):
        pass

    def write_throttled_update(self, msg):
        pass



class PortTestCase(unittest.TestCase):
    """Tests that all Port implementations must pass."""
    HTTP_PORTS = (8000, 8080, 8443)
    WEBSOCKET_PORTS = (8880,)

    # Subclasses override this to point to their Port subclass.
    os_name = None
    os_version = None
    port_maker = TestWebKitPort
    port_name = None

    def make_port(self, host=None, port_name=None, options=None, os_name=None, os_version=None, **kwargs):
        host = host or MockSystemHost(os_name=(os_name or self.os_name), os_version=(os_version or self.os_version))
        options = options or MockOptions(configuration='Release')
        port_name = port_name or self.port_name
        port_name = self.port_maker.determine_full_port_name(host, options, port_name)
        port = self.port_maker(host, port_name, options=options, **kwargs)
        port._config.build_directory = lambda configuration: '/mock-build'
        return port

    def make_wdiff_available(self, port):
        port._wdiff_available = True

    def test_check_build(self):
        port = self.make_port()
        port._check_file_exists = lambda path, desc: True
        if port._dump_reader:
            port._dump_reader.check_is_functional = lambda: True
        port._options.build = True
        port._check_driver_build_up_to_date = lambda config: True
        port.check_httpd = lambda: True
        oc = OutputCapture()
        try:
            oc.capture_output()
            self.assertEqual(port.check_build(needs_http=True, printer=FakePrinter()),
                             test_run_results.OK_EXIT_STATUS)
        finally:
            out, err, logs = oc.restore_output()
            self.assertIn('pretty patches', logs)         # We should get a warning about PrettyPatch being missing,
            self.assertNotIn('build requirements', logs)  # but not the driver itself.

        port._check_file_exists = lambda path, desc: False
        port._check_driver_build_up_to_date = lambda config: False
        try:
            oc.capture_output()
            self.assertEqual(port.check_build(needs_http=True, printer=FakePrinter()),
                            test_run_results.UNEXPECTED_ERROR_EXIT_STATUS)
        finally:
            out, err, logs = oc.restore_output()
            self.assertIn('pretty patches', logs)        # And, hereere we should get warnings about both.
            self.assertIn('build requirements', logs)

    def test_default_max_locked_shards(self):
        port = self.make_port()
        port.default_child_processes = lambda: 16
        self.assertEqual(port.default_max_locked_shards(), 4)
        port.default_child_processes = lambda: 2
        self.assertEqual(port.default_max_locked_shards(), 1)

    def test_default_timeout_ms(self):
        self.assertEqual(self.make_port(options=MockOptions(configuration='Release')).default_timeout_ms(), 6000)
        self.assertEqual(self.make_port(options=MockOptions(configuration='Debug')).default_timeout_ms(), 18000)

    def test_default_pixel_tests(self):
        self.assertEqual(self.make_port().default_pixel_tests(), True)

    def test_driver_cmd_line(self):
        port = self.make_port()
        self.assertTrue(len(port.driver_cmd_line()))

        options = MockOptions(additional_drt_flag=['--foo=bar', '--foo=baz'])
        port = self.make_port(options=options)
        cmd_line = port.driver_cmd_line()
        self.assertTrue('--foo=bar' in cmd_line)
        self.assertTrue('--foo=baz' in cmd_line)

    def assert_servers_are_down(self, host, ports):
        for port in ports:
            try:
                test_socket = socket.socket()
                test_socket.connect((host, port))
                self.fail()
            except IOError, e:
                self.assertTrue(e.errno in (errno.ECONNREFUSED, errno.ECONNRESET))
            finally:
                test_socket.close()

    def assert_servers_are_up(self, host, ports):
        for port in ports:
            try:
                test_socket = socket.socket()
                test_socket.connect((host, port))
            except IOError, e:
                self.fail('failed to connect to %s:%d' % (host, port))
            finally:
                test_socket.close()

    def test_diff_image__missing_both(self):
        port = self.make_port()
        self.assertEqual(port.diff_image(None, None), (None, None))
        self.assertEqual(port.diff_image(None, ''), (None, None))
        self.assertEqual(port.diff_image('', None), (None, None))

        self.assertEqual(port.diff_image('', ''), (None, None))

    def test_diff_image__missing_actual(self):
        port = self.make_port()
        self.assertEqual(port.diff_image(None, 'foo'), ('foo', None))
        self.assertEqual(port.diff_image('', 'foo'), ('foo', None))

    def test_diff_image__missing_expected(self):
        port = self.make_port()
        self.assertEqual(port.diff_image('foo', None), ('foo', None))
        self.assertEqual(port.diff_image('foo', ''), ('foo', None))

    def test_diff_image(self):
        def _path_to_image_diff():
            return "/path/to/image_diff"

        port = self.make_port()
        port._path_to_image_diff = _path_to_image_diff

        mock_image_diff = "MOCK Image Diff"

        def mock_run_command(args):
            port._filesystem.write_binary_file(args[4], mock_image_diff)
            return 1

        # Images are different.
        port._executive = MockExecutive2(run_command_fn=mock_run_command)
        self.assertEqual(mock_image_diff, port.diff_image("EXPECTED", "ACTUAL")[0])

        # Images are the same.
        port._executive = MockExecutive2(exit_code=0)
        self.assertEqual(None, port.diff_image("EXPECTED", "ACTUAL")[0])

        # There was some error running image_diff.
        port._executive = MockExecutive2(exit_code=2)
        exception_raised = False
        try:
            port.diff_image("EXPECTED", "ACTUAL")
        except ValueError, e:
            exception_raised = True
        self.assertFalse(exception_raised)

    def test_diff_image_crashed(self):
        port = self.make_port()
        port._executive = MockExecutive2(exit_code=2)
        self.assertEqual(port.diff_image("EXPECTED", "ACTUAL"), (None, 'Image diff returned an exit code of 2. See http://crbug.com/278596'))

    def test_check_wdiff(self):
        port = self.make_port()
        port.check_wdiff()

    def test_wdiff_text_fails(self):
        host = MockSystemHost(os_name=self.os_name, os_version=self.os_version)
        host.executive = MockExecutive(should_throw=True)
        port = self.make_port(host=host)
        port._executive = host.executive  # AndroidPortTest.make_port sets its own executive, so reset that as well.

        # This should raise a ScriptError that gets caught and turned into the
        # error text, and also mark wdiff as not available.
        self.make_wdiff_available(port)
        self.assertTrue(port.wdiff_available())
        diff_txt = port.wdiff_text("/tmp/foo.html", "/tmp/bar.html")
        self.assertEqual(diff_txt, port._wdiff_error_html)
        self.assertFalse(port.wdiff_available())

    def test_missing_symbol_to_skipped_tests(self):
        # Test that we get the chromium skips and not the webkit default skips
        port = self.make_port()
        skip_dict = port._missing_symbol_to_skipped_tests()
        if port.PORT_HAS_AUDIO_CODECS_BUILT_IN:
            self.assertEqual(skip_dict, {})
        else:
            self.assertTrue('ff_mp3_decoder' in skip_dict)
        self.assertFalse('WebGLShader' in skip_dict)

    def test_test_configuration(self):
        port = self.make_port()
        self.assertTrue(port.test_configuration())

    def test_all_test_configurations(self):
        """Validate the complete set of configurations this port knows about."""
        port = self.make_port()
        self.assertEqual(set(port.all_test_configurations()), set([
            TestConfiguration('snowleopard', 'x86', 'debug'),
            TestConfiguration('snowleopard', 'x86', 'release'),
            TestConfiguration('lion', 'x86', 'debug'),
            TestConfiguration('lion', 'x86', 'release'),
            TestConfiguration('retina', 'x86', 'debug'),
            TestConfiguration('retina', 'x86', 'release'),
            TestConfiguration('mountainlion', 'x86', 'debug'),
            TestConfiguration('mountainlion', 'x86', 'release'),
            TestConfiguration('mavericks', 'x86', 'debug'),
            TestConfiguration('mavericks', 'x86', 'release'),
            TestConfiguration('xp', 'x86', 'debug'),
            TestConfiguration('xp', 'x86', 'release'),
            TestConfiguration('win7', 'x86', 'debug'),
            TestConfiguration('win7', 'x86', 'release'),
            TestConfiguration('lucid', 'x86', 'debug'),
            TestConfiguration('lucid', 'x86', 'release'),
            TestConfiguration('lucid', 'x86_64', 'debug'),
            TestConfiguration('lucid', 'x86_64', 'release'),
            TestConfiguration('icecreamsandwich', 'x86', 'debug'),
            TestConfiguration('icecreamsandwich', 'x86', 'release'),
        ]))
    def test_get_crash_log(self):
        port = self.make_port()
        self.assertEqual(port._get_crash_log(None, None, None, None, newer_than=None),
           (None,
            'crash log for <unknown process name> (pid <unknown>):\n'
            'STDOUT: <empty>\n'
            'STDERR: <empty>\n'))

        self.assertEqual(port._get_crash_log('foo', 1234, 'out bar\nout baz', 'err bar\nerr baz\n', newer_than=None),
            ('err bar\nerr baz\n',
             'crash log for foo (pid 1234):\n'
             'STDOUT: out bar\n'
             'STDOUT: out baz\n'
             'STDERR: err bar\n'
             'STDERR: err baz\n'))

        self.assertEqual(port._get_crash_log('foo', 1234, 'foo\xa6bar', 'foo\xa6bar', newer_than=None),
            ('foo\xa6bar',
             u'crash log for foo (pid 1234):\n'
             u'STDOUT: foo\ufffdbar\n'
             u'STDERR: foo\ufffdbar\n'))

        self.assertEqual(port._get_crash_log('foo', 1234, 'foo\xa6bar', 'foo\xa6bar', newer_than=1.0),
            ('foo\xa6bar',
             u'crash log for foo (pid 1234):\n'
             u'STDOUT: foo\ufffdbar\n'
             u'STDERR: foo\ufffdbar\n'))

    def assert_build_path(self, options, dirs, expected_path):
        port = self.make_port(options=options)
        for directory in dirs:
            port.host.filesystem.maybe_make_directory(directory)
        self.assertEqual(port._build_path(), expected_path)

    def test_expectations_files(self):
        port = self.make_port()

        generic_path = port.path_to_generic_test_expectations_file()
        chromium_overrides_path = port.path_from_chromium_base(
            'webkit', 'tools', 'layout_tests', 'test_expectations.txt')
        never_fix_tests_path = port._filesystem.join(port.layout_tests_dir(), 'NeverFixTests')
        stale_tests_path = port._filesystem.join(port.layout_tests_dir(), 'StaleTestExpectations')
        slow_tests_path = port._filesystem.join(port.layout_tests_dir(), 'SlowTests')
        flaky_tests_path = port._filesystem.join(port.layout_tests_dir(), 'FlakyTests')
        skia_overrides_path = port.path_from_chromium_base(
            'skia', 'skia_test_expectations.txt')

        port._filesystem.write_text_file(skia_overrides_path, 'dummy text')

        w3c_overrides_path = port.path_from_chromium_base(
            'webkit', 'tools', 'layout_tests', 'test_expectations_w3c.txt')
        port._filesystem.write_text_file(w3c_overrides_path, 'dummy text')

        port._options.builder_name = 'DUMMY_BUILDER_NAME'
        self.assertEqual(port.expectations_files(),
                         [generic_path, skia_overrides_path, w3c_overrides_path,
                          never_fix_tests_path, stale_tests_path, slow_tests_path,
                          flaky_tests_path, chromium_overrides_path])

        port._options.builder_name = 'builder (deps)'
        self.assertEqual(port.expectations_files(),
                         [generic_path, skia_overrides_path, w3c_overrides_path,
                          never_fix_tests_path, stale_tests_path, slow_tests_path,
                          flaky_tests_path, chromium_overrides_path])

        # A builder which does NOT observe the Chromium test_expectations,
        # but still observes the Skia test_expectations...
        port._options.builder_name = 'builder'
        self.assertEqual(port.expectations_files(),
                         [generic_path, skia_overrides_path, w3c_overrides_path,
                          never_fix_tests_path, stale_tests_path, slow_tests_path,
                          flaky_tests_path])

    def test_check_sys_deps(self):
        port = self.make_port()
        port._executive = MockExecutive2(exit_code=0)
        self.assertEqual(port.check_sys_deps(needs_http=False), test_run_results.OK_EXIT_STATUS)
        port._executive = MockExecutive2(exit_code=1, output='testing output failure')
        self.assertEqual(port.check_sys_deps(needs_http=False), test_run_results.SYS_DEPS_EXIT_STATUS)

    def test_expectations_ordering(self):
        port = self.make_port()
        for path in port.expectations_files():
            port._filesystem.write_text_file(path, '')
        ordered_dict = port.expectations_dict()
        self.assertEqual(port.path_to_generic_test_expectations_file(), ordered_dict.keys()[0])

        options = MockOptions(additional_expectations=['/tmp/foo', '/tmp/bar'])
        port = self.make_port(options=options)
        for path in port.expectations_files():
            port._filesystem.write_text_file(path, '')
        port._filesystem.write_text_file('/tmp/foo', 'foo')
        port._filesystem.write_text_file('/tmp/bar', 'bar')
        ordered_dict = port.expectations_dict()
        self.assertEqual(ordered_dict.keys()[-2:], options.additional_expectations)  # pylint: disable=E1101
        self.assertEqual(ordered_dict.values()[-2:], ['foo', 'bar'])

    def test_skipped_directories_for_symbols(self):
        # This first test confirms that the commonly found symbols result in the expected skipped directories.
        symbols_string = " ".join(["fooSymbol"])
        expected_directories = set([
            "webaudio/codec-tests/mp3",
            "webaudio/codec-tests/aac",
        ])

        result_directories = set(TestWebKitPort(symbols_string=symbols_string)._skipped_tests_for_unsupported_features(test_list=['webaudio/codec-tests/mp3/foo.html']))
        self.assertEqual(result_directories, expected_directories)

        # Test that the nm string parsing actually works:
        symbols_string = """
000000000124f498 s __ZZN7WebCore13ff_mp3_decoder12replaceChildEPS0_S1_E19__PRETTY_FUNCTION__
000000000124f500 s __ZZN7WebCore13ff_mp3_decoder13addChildAboveEPS0_S1_E19__PRETTY_FUNCTION__
000000000124f670 s __ZZN7WebCore13ff_mp3_decoder13addChildBelowEPS0_S1_E19__PRETTY_FUNCTION__
"""
        # Note 'compositing' is not in the list of skipped directories (hence the parsing of GraphicsLayer worked):
        expected_directories = set([
            "webaudio/codec-tests/aac",
        ])
        result_directories = set(TestWebKitPort(symbols_string=symbols_string)._skipped_tests_for_unsupported_features(test_list=['webaudio/codec-tests/mp3/foo.html']))
        self.assertEqual(result_directories, expected_directories)

    def _assert_config_file_for_platform(self, port, platform, config_file):
        self.assertEqual(port._apache_config_file_name_for_platform(platform), config_file)

    def test_linux_distro_detection(self):
        port = TestWebKitPort()
        self.assertFalse(port._is_redhat_based())
        self.assertFalse(port._is_debian_based())

        port._filesystem = MockFileSystem({'/etc/redhat-release': ''})
        self.assertTrue(port._is_redhat_based())
        self.assertFalse(port._is_debian_based())

        port._filesystem = MockFileSystem({'/etc/debian_version': ''})
        self.assertFalse(port._is_redhat_based())
        self.assertTrue(port._is_debian_based())

    def test_apache_config_file_name_for_platform(self):
        port = TestWebKitPort()
        self._assert_config_file_for_platform(port, 'cygwin', 'cygwin-httpd.conf')

        self._assert_config_file_for_platform(port, 'linux2', 'apache2-httpd.conf')
        self._assert_config_file_for_platform(port, 'linux3', 'apache2-httpd.conf')

        port._is_redhat_based = lambda: True
        port._apache_version = lambda: '2.2'
        self._assert_config_file_for_platform(port, 'linux2', 'fedora-httpd-2.2.conf')

        port = TestWebKitPort()
        port._is_debian_based = lambda: True
        port._apache_version = lambda: '2.2'
        self._assert_config_file_for_platform(port, 'linux2', 'debian-httpd-2.2.conf')

        self._assert_config_file_for_platform(port, 'mac', 'apache2-httpd.conf')
        self._assert_config_file_for_platform(port, 'win32', 'apache2-httpd.conf')  # win32 isn't a supported sys.platform.  AppleWin/WinCairo/WinCE ports all use cygwin.
        self._assert_config_file_for_platform(port, 'barf', 'apache2-httpd.conf')

    def test_path_to_apache_config_file(self):
        port = TestWebKitPort()

        saved_environ = os.environ.copy()
        try:
            os.environ['WEBKIT_HTTP_SERVER_CONF_PATH'] = '/path/to/httpd.conf'
            self.assertRaises(IOError, port.path_to_apache_config_file)
            port._filesystem.write_text_file('/existing/httpd.conf', 'Hello, world!')
            os.environ['WEBKIT_HTTP_SERVER_CONF_PATH'] = '/existing/httpd.conf'
            self.assertEqual(port.path_to_apache_config_file(), '/existing/httpd.conf')
        finally:
            os.environ = saved_environ.copy()

        # Mock out _apache_config_file_name_for_platform to ignore the passed sys.platform value.
        port._apache_config_file_name_for_platform = lambda platform: 'httpd.conf'
        self.assertEqual(port.path_to_apache_config_file(), '/mock-checkout/third_party/WebKit/tests/http/conf/httpd.conf')

        # Check that even if we mock out _apache_config_file_name, the environment variable takes precedence.
        saved_environ = os.environ.copy()
        try:
            os.environ['WEBKIT_HTTP_SERVER_CONF_PATH'] = '/existing/httpd.conf'
            self.assertEqual(port.path_to_apache_config_file(), '/existing/httpd.conf')
        finally:
            os.environ = saved_environ.copy()

    def test_additional_platform_directory(self):
        port = self.make_port(options=MockOptions(additional_platform_directory=['/tmp/foo']))
        self.assertEqual(port.baseline_search_path()[0], '/tmp/foo')
