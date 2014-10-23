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

import logging
import optparse
import sys
import tempfile
import unittest

from webkitpy.common.system.executive import Executive, ScriptError
from webkitpy.common.system import executive_mock
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.common.system.path import abspath_to_uri
from webkitpy.tool.mocktool import MockOptions
from webkitpy.common.system.executive_mock import MockExecutive, MockExecutive2
from webkitpy.common.system.systemhost_mock import MockSystemHost

from webkitpy.layout_tests.port import Port, Driver, DriverOutput
from webkitpy.layout_tests.port.base import VirtualTestSuite
from webkitpy.layout_tests.port.test import add_unit_tests_to_mock_filesystem, TestPort

class PortTest(unittest.TestCase):
    def make_port(self, executive=None, with_tests=False, port_name=None, **kwargs):
        host = MockSystemHost()
        if executive:
            host.executive = executive
        if with_tests:
            add_unit_tests_to_mock_filesystem(host.filesystem)
            return TestPort(host, **kwargs)
        return Port(host, port_name or 'baseport', **kwargs)

    def test_default_child_processes(self):
        port = self.make_port()
        self.assertIsNotNone(port.default_child_processes())

    def test_format_wdiff_output_as_html(self):
        output = "OUTPUT %s %s %s" % (Port._WDIFF_DEL, Port._WDIFF_ADD, Port._WDIFF_END)
        html = self.make_port()._format_wdiff_output_as_html(output)
        expected_html = "<head><style>.del { background: #faa; } .add { background: #afa; }</style></head><pre>OUTPUT <span class=del> <span class=add> </span></pre>"
        self.assertEqual(html, expected_html)

    def test_wdiff_command(self):
        port = self.make_port()
        port._path_to_wdiff = lambda: "/path/to/wdiff"
        command = port._wdiff_command("/actual/path", "/expected/path")
        expected_command = [
            "/path/to/wdiff",
            "--start-delete=##WDIFF_DEL##",
            "--end-delete=##WDIFF_END##",
            "--start-insert=##WDIFF_ADD##",
            "--end-insert=##WDIFF_END##",
            "/actual/path",
            "/expected/path",
        ]
        self.assertEqual(command, expected_command)

    def _file_with_contents(self, contents, encoding="utf-8"):
        new_file = tempfile.NamedTemporaryFile()
        new_file.write(contents.encode(encoding))
        new_file.flush()
        return new_file

    def test_pretty_patch_os_error(self):
        port = self.make_port(executive=executive_mock.MockExecutive2(exception=OSError))
        oc = OutputCapture()
        oc.capture_output()
        self.assertEqual(port.pretty_patch_text("patch.txt"),
                         port._pretty_patch_error_html)

        # This tests repeated calls to make sure we cache the result.
        self.assertEqual(port.pretty_patch_text("patch.txt"),
                         port._pretty_patch_error_html)
        oc.restore_output()

    def test_pretty_patch_script_error(self):
        # FIXME: This is some ugly white-box test hacking ...
        port = self.make_port(executive=executive_mock.MockExecutive2(exception=ScriptError))
        port._pretty_patch_available = True
        self.assertEqual(port.pretty_patch_text("patch.txt"),
                         port._pretty_patch_error_html)

        # This tests repeated calls to make sure we cache the result.
        self.assertEqual(port.pretty_patch_text("patch.txt"),
                         port._pretty_patch_error_html)

    def test_wdiff_text(self):
        port = self.make_port()
        port.wdiff_available = lambda: True
        port._run_wdiff = lambda a, b: 'PASS'
        self.assertEqual('PASS', port.wdiff_text(None, None))

    def test_diff_text(self):
        port = self.make_port()
        # Make sure that we don't run into decoding exceptions when the
        # filenames are unicode, with regular or malformed input (expected or
        # actual input is always raw bytes, not unicode).
        port.diff_text('exp', 'act', 'exp.txt', 'act.txt')
        port.diff_text('exp', 'act', u'exp.txt', 'act.txt')
        port.diff_text('exp', 'act', u'a\xac\u1234\u20ac\U00008000', 'act.txt')

        port.diff_text('exp' + chr(255), 'act', 'exp.txt', 'act.txt')
        port.diff_text('exp' + chr(255), 'act', u'exp.txt', 'act.txt')

        # Though expected and actual files should always be read in with no
        # encoding (and be stored as str objects), test unicode inputs just to
        # be safe.
        port.diff_text(u'exp', 'act', 'exp.txt', 'act.txt')
        port.diff_text(
            u'a\xac\u1234\u20ac\U00008000', 'act', 'exp.txt', 'act.txt')

        # And make sure we actually get diff output.
        diff = port.diff_text('foo', 'bar', 'exp.txt', 'act.txt')
        self.assertIn('foo', diff)
        self.assertIn('bar', diff)
        self.assertIn('exp.txt', diff)
        self.assertIn('act.txt', diff)
        self.assertNotIn('nosuchthing', diff)

        # Test for missing newline at end of file diff output.
        content_a = "Hello\n\nWorld"
        content_b = "Hello\n\nWorld\n\n\n"
        expected = "--- exp.txt\n+++ act.txt\n@@ -1,3 +1,5 @@\n Hello\n \n-World\n\ No newline at end of file\n+World\n+\n+\n"
        self.assertEqual(expected, port.diff_text(content_a, content_b, 'exp.txt', 'act.txt'))

    def test_setup_test_run(self):
        port = self.make_port()
        # This routine is a no-op. We just test it for coverage.
        port.setup_test_run()

    def test_test_dirs(self):
        port = self.make_port()
        port.host.filesystem.write_text_file(port.layout_tests_dir() + '/canvas/test', '')
        port.host.filesystem.write_text_file(port.layout_tests_dir() + '/css2.1/test', '')
        dirs = port.test_dirs()
        self.assertIn('canvas', dirs)
        self.assertIn('css2.1', dirs)

    def test_skipped_perf_tests(self):
        port = self.make_port()

        def add_text_file(dirname, filename, content='some content'):
            dirname = port.host.filesystem.join(port.perf_tests_dir(), dirname)
            port.host.filesystem.maybe_make_directory(dirname)
            port.host.filesystem.write_text_file(port.host.filesystem.join(dirname, filename), content)

        add_text_file('inspector', 'test1.html')
        add_text_file('inspector', 'unsupported_test1.html')
        add_text_file('inspector', 'test2.html')
        add_text_file('inspector/resources', 'resource_file.html')
        add_text_file('unsupported', 'unsupported_test2.html')
        add_text_file('', 'Skipped', '\n'.join(['Layout', '', 'SunSpider', 'Supported/some-test.html']))
        self.assertEqual(port.skipped_perf_tests(), ['Layout', 'SunSpider', 'Supported/some-test.html'])

    def test_get_option__set(self):
        options, args = optparse.OptionParser().parse_args([])
        options.foo = 'bar'
        port = self.make_port(options=options)
        self.assertEqual(port.get_option('foo'), 'bar')

    def test_get_option__unset(self):
        port = self.make_port()
        self.assertIsNone(port.get_option('foo'))

    def test_get_option__default(self):
        port = self.make_port()
        self.assertEqual(port.get_option('foo', 'bar'), 'bar')

    def test_additional_platform_directory(self):
        port = self.make_port(port_name='foo')
        port.default_baseline_search_path = lambda: ['tests/platform/foo']
        layout_test_dir = port.layout_tests_dir()
        test_file = 'fast/test.html'

        # No additional platform directory
        self.assertEqual(
            port.expected_baselines(test_file, '.txt'),
            [(None, 'fast/test-expected.txt')])
        self.assertEqual(port.baseline_path(), 'tests/platform/foo')

        # Simple additional platform directory
        port._options.additional_platform_directory = ['/tmp/local-baselines']
        port._filesystem.write_text_file('/tmp/local-baselines/fast/test-expected.txt', 'foo')
        self.assertEqual(
            port.expected_baselines(test_file, '.txt'),
            [('/tmp/local-baselines', 'fast/test-expected.txt')])
        self.assertEqual(port.baseline_path(), '/tmp/local-baselines')

        # Multiple additional platform directories
        port._options.additional_platform_directory = ['/foo', '/tmp/local-baselines']
        self.assertEqual(
            port.expected_baselines(test_file, '.txt'),
            [('/tmp/local-baselines', 'fast/test-expected.txt')])
        self.assertEqual(port.baseline_path(), '/foo')

    def test_nonexistant_expectations(self):
        port = self.make_port(port_name='foo')
        port.expectations_files = lambda: ['/mock-checkout/third_party/WebKit/tests/platform/exists/TestExpectations', '/mock-checkout/third_party/WebKit/tests/platform/nonexistant/TestExpectations']
        port._filesystem.write_text_file('/mock-checkout/third_party/WebKit/tests/platform/exists/TestExpectations', '')
        self.assertEqual('\n'.join(port.expectations_dict().keys()), '/mock-checkout/third_party/WebKit/tests/platform/exists/TestExpectations')

    def test_additional_expectations(self):
        port = self.make_port(port_name='foo')
        port.port_name = 'foo'
        port._filesystem.write_text_file('/mock-checkout/third_party/WebKit/tests/platform/foo/TestExpectations', '')
        port._filesystem.write_text_file(
            '/tmp/additional-expectations-1.txt', 'content1\n')
        port._filesystem.write_text_file(
            '/tmp/additional-expectations-2.txt', 'content2\n')

        self.assertEqual('\n'.join(port.expectations_dict().values()), '')

        port._options.additional_expectations = [
            '/tmp/additional-expectations-1.txt']
        self.assertEqual('\n'.join(port.expectations_dict().values()), 'content1\n')

        port._options.additional_expectations = [
            '/tmp/nonexistent-file', '/tmp/additional-expectations-1.txt']
        self.assertEqual('\n'.join(port.expectations_dict().values()), 'content1\n')

        port._options.additional_expectations = [
            '/tmp/additional-expectations-1.txt', '/tmp/additional-expectations-2.txt']
        self.assertEqual('\n'.join(port.expectations_dict().values()), 'content1\n\ncontent2\n')

    def test_additional_env_var(self):
        port = self.make_port(options=optparse.Values({'additional_env_var': ['FOO=BAR', 'BAR=FOO']}))
        self.assertEqual(port.get_option('additional_env_var'), ['FOO=BAR', 'BAR=FOO'])
        environment = port.setup_environ_for_server()
        self.assertTrue(('FOO' in environment) & ('BAR' in environment))
        self.assertEqual(environment['FOO'], 'BAR')
        self.assertEqual(environment['BAR'], 'FOO')

    def test_find_no_paths_specified(self):
        port = self.make_port(with_tests=True)
        layout_tests_dir = port.layout_tests_dir()
        tests = port.tests([])
        self.assertNotEqual(len(tests), 0)

    def test_find_one_test(self):
        port = self.make_port(with_tests=True)
        tests = port.tests(['failures/expected/image.html'])
        self.assertEqual(len(tests), 1)

    def test_find_glob(self):
        port = self.make_port(with_tests=True)
        tests = port.tests(['failures/expected/im*'])
        self.assertEqual(len(tests), 2)

    def test_find_with_skipped_directories(self):
        port = self.make_port(with_tests=True)
        tests = port.tests(['userscripts'])
        self.assertNotIn('userscripts/resources/iframe.html', tests)

    def test_find_with_skipped_directories_2(self):
        port = self.make_port(with_tests=True)
        tests = port.tests(['userscripts/resources'])
        self.assertEqual(tests, [])

    def test_is_test_file(self):
        filesystem = MockFileSystem()
        self.assertTrue(Port.is_test_file(filesystem, '', 'foo.html'))
        self.assertTrue(Port.is_test_file(filesystem, '', 'foo.svg'))
        self.assertTrue(Port.is_test_file(filesystem, '', 'test-ref-test.html'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo.png'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-expected.html'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-expected.svg'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-expected.xht'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-expected-mismatch.html'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-expected-mismatch.svg'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-expected-mismatch.xhtml'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-ref.html'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-notref.html'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-notref.xht'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'foo-ref.xhtml'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'ref-foo.html'))
        self.assertFalse(Port.is_test_file(filesystem, '', 'notref-foo.xhr'))

    def test_parse_reftest_list(self):
        port = self.make_port(with_tests=True)
        port.host.filesystem.files['bar/reftest.list'] = "\n".join(["== test.html test-ref.html",
        "",
        "# some comment",
        "!= test-2.html test-notref.html # more comments",
        "== test-3.html test-ref.html",
        "== test-3.html test-ref2.html",
        "!= test-3.html test-notref.html",
        "fuzzy(80,500) == test-3 test-ref.html"])

        # Note that we don't support the syntax in the last line; the code should ignore it, rather than crashing.

        reftest_list = Port._parse_reftest_list(port.host.filesystem, 'bar')
        self.assertEqual(reftest_list, {'bar/test.html': [('==', 'bar/test-ref.html')],
            'bar/test-2.html': [('!=', 'bar/test-notref.html')],
            'bar/test-3.html': [('==', 'bar/test-ref.html'), ('==', 'bar/test-ref2.html'), ('!=', 'bar/test-notref.html')]})

    def test_reference_files(self):
        port = self.make_port(with_tests=True)
        self.assertEqual(port.reference_files('passes/svgreftest.svg'), [('==', port.layout_tests_dir() + '/passes/svgreftest-expected.svg')])
        self.assertEqual(port.reference_files('passes/xhtreftest.svg'), [('==', port.layout_tests_dir() + '/passes/xhtreftest-expected.html')])
        self.assertEqual(port.reference_files('passes/phpreftest.php'), [('!=', port.layout_tests_dir() + '/passes/phpreftest-expected-mismatch.svg')])

    def test_operating_system(self):
        self.assertEqual('mac', self.make_port().operating_system())

    def test_http_server_supports_ipv6(self):
        port = self.make_port()
        self.assertTrue(port.http_server_supports_ipv6())
        port.host.platform.os_name = 'cygwin'
        self.assertFalse(port.http_server_supports_ipv6())
        port.host.platform.os_name = 'win'
        self.assertFalse(port.http_server_supports_ipv6())

    def test_check_httpd_success(self):
        port = self.make_port(executive=MockExecutive2())
        port.path_to_apache = lambda: '/usr/sbin/httpd'
        capture = OutputCapture()
        capture.capture_output()
        self.assertTrue(port.check_httpd())
        _, _, logs = capture.restore_output()
        self.assertEqual('', logs)

    def test_httpd_returns_error_code(self):
        port = self.make_port(executive=MockExecutive2(exit_code=1))
        port.path_to_apache = lambda: '/usr/sbin/httpd'
        capture = OutputCapture()
        capture.capture_output()
        self.assertFalse(port.check_httpd())
        _, _, logs = capture.restore_output()
        self.assertEqual('httpd seems broken. Cannot run http tests.\n', logs)

    def test_test_exists(self):
        port = self.make_port(with_tests=True)
        self.assertTrue(port.test_exists('passes'))
        self.assertTrue(port.test_exists('passes/text.html'))
        self.assertFalse(port.test_exists('passes/does_not_exist.html'))

        self.assertTrue(port.test_exists('virtual'))
        self.assertFalse(port.test_exists('virtual/does_not_exist.html'))
        self.assertTrue(port.test_exists('virtual/passes/text.html'))

    def test_test_isfile(self):
        port = self.make_port(with_tests=True)
        self.assertFalse(port.test_isfile('passes'))
        self.assertTrue(port.test_isfile('passes/text.html'))
        self.assertFalse(port.test_isfile('passes/does_not_exist.html'))

        self.assertFalse(port.test_isfile('virtual'))
        self.assertTrue(port.test_isfile('virtual/passes/text.html'))
        self.assertFalse(port.test_isfile('virtual/does_not_exist.html'))

    def test_test_isdir(self):
        port = self.make_port(with_tests=True)
        self.assertTrue(port.test_isdir('passes'))
        self.assertFalse(port.test_isdir('passes/text.html'))
        self.assertFalse(port.test_isdir('passes/does_not_exist.html'))
        self.assertFalse(port.test_isdir('passes/does_not_exist/'))

        self.assertTrue(port.test_isdir('virtual'))
        self.assertFalse(port.test_isdir('virtual/does_not_exist.html'))
        self.assertFalse(port.test_isdir('virtual/does_not_exist/'))
        self.assertFalse(port.test_isdir('virtual/passes/text.html'))

    def test_tests(self):
        port = self.make_port(with_tests=True)
        tests = port.tests([])
        self.assertIn('passes/text.html', tests)
        self.assertIn('virtual/passes/text.html', tests)

        tests = port.tests(['passes'])
        self.assertIn('passes/text.html', tests)
        self.assertIn('passes/passes/test-virtual-passes.html', tests)
        self.assertNotIn('virtual/passes/text.html', tests)

        tests = port.tests(['virtual/passes'])
        self.assertNotIn('passes/text.html', tests)
        self.assertIn('virtual/passes/test-virtual-passes.html', tests)
        self.assertIn('virtual/passes/passes/test-virtual-passes.html', tests)
        self.assertNotIn('virtual/passes/test-virtual-virtual/passes.html', tests)
        self.assertNotIn('virtual/passes/virtual/passes/test-virtual-passes.html', tests)

    def test_build_path(self):
        port = self.make_port(options=optparse.Values({'build_directory': '/my-build-directory/'}))
        self.assertEqual(port._build_path(), '/my-build-directory/Release')

    def test_dont_require_http_server(self):
        port = self.make_port()
        self.assertEqual(port.requires_http_server(), False)


class NaturalCompareTest(unittest.TestCase):
    def setUp(self):
        self._port = TestPort(MockSystemHost())

    def assert_cmp(self, x, y, result):
        self.assertEqual(cmp(self._port._natural_sort_key(x), self._port._natural_sort_key(y)), result)

    def test_natural_compare(self):
        self.assert_cmp('a', 'a', 0)
        self.assert_cmp('ab', 'a', 1)
        self.assert_cmp('a', 'ab', -1)
        self.assert_cmp('', '', 0)
        self.assert_cmp('', 'ab', -1)
        self.assert_cmp('1', '2', -1)
        self.assert_cmp('2', '1', 1)
        self.assert_cmp('1', '10', -1)
        self.assert_cmp('2', '10', -1)
        self.assert_cmp('foo_1.html', 'foo_2.html', -1)
        self.assert_cmp('foo_1.1.html', 'foo_2.html', -1)
        self.assert_cmp('foo_1.html', 'foo_10.html', -1)
        self.assert_cmp('foo_2.html', 'foo_10.html', -1)
        self.assert_cmp('foo_23.html', 'foo_10.html', 1)
        self.assert_cmp('foo_23.html', 'foo_100.html', -1)


class KeyCompareTest(unittest.TestCase):
    def setUp(self):
        self._port = TestPort(MockSystemHost())

    def assert_cmp(self, x, y, result):
        self.assertEqual(cmp(self._port.test_key(x), self._port.test_key(y)), result)

    def test_test_key(self):
        self.assert_cmp('/a', '/a', 0)
        self.assert_cmp('/a', '/b', -1)
        self.assert_cmp('/a2', '/a10', -1)
        self.assert_cmp('/a2/foo', '/a10/foo', -1)
        self.assert_cmp('/a/foo11', '/a/foo2', 1)
        self.assert_cmp('/ab', '/a/a/b', -1)
        self.assert_cmp('/a/a/b', '/ab', 1)
        self.assert_cmp('/foo-bar/baz', '/foo/baz', -1)


class VirtualTestSuiteTest(unittest.TestCase):
    def test_basic(self):
        suite = VirtualTestSuite('suite', 'base/foo', ['--args'])
        self.assertEqual(suite.name, 'virtual/suite/base/foo')
        self.assertEqual(suite.base, 'base/foo')
        self.assertEqual(suite.args, ['--args'])

    def test_no_slash(self):
        suite = VirtualTestSuite('suite/bar', 'base/foo', ['--args'])
        self.assertFalse(hasattr(suite, 'name'))
        self.assertFalse(hasattr(suite, 'base'))
        self.assertFalse(hasattr(suite, 'args'))

    def test_legacy(self):
        suite = VirtualTestSuite('suite/bar', 'base/foo', ['--args'], use_legacy_naming=True)
        self.assertEqual(suite.name, 'virtual/suite/bar')
        self.assertEqual(suite.base, 'base/foo')
        self.assertEqual(suite.args, ['--args'])
