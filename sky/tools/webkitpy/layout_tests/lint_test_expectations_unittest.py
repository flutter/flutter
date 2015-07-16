# Copyright (C) 2012 Google Inc. All rights reserved.
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

import StringIO
import optparse
import unittest

from webkitpy.common.host_mock import MockHost
from webkitpy.layout_tests import lint_test_expectations


class FakePort(object):
    def __init__(self, host, name, path):
        self.host = host
        self.name = name
        self.path = path

    def test_configuration(self):
        return None

    def expectations_dict(self):
        self.host.ports_parsed.append(self.name)
        return {self.path: ''}

    def bot_expectations(self):
        return {}

    def skipped_layout_tests(self, _):
        return set([])

    def all_test_configurations(self):
        return []

    def configuration_specifier_macros(self):
        return []

    def get_option(self, _, val):
        return val

    def path_to_generic_test_expectations_file(self):
        return ''

class FakeFactory(object):
    def __init__(self, host, ports):
        self.host = host
        self.ports = {}
        for port in ports:
            self.ports[port.name] = port

    def get(self, port_name='a', *args, **kwargs):  # pylint: disable=W0613,E0202
        return self.ports[port_name]

    def all_port_names(self, platform=None):  # pylint: disable=W0613,E0202
        return sorted(self.ports.keys())


class LintTest(unittest.TestCase):
    def test_all_configurations(self):
        host = MockHost()
        host.ports_parsed = []
        host.port_factory = FakeFactory(host, (FakePort(host, 'a', 'path-to-a'),
                                               FakePort(host, 'b', 'path-to-b'),
                                               FakePort(host, 'b-win', 'path-to-b')))

        logging_stream = StringIO.StringIO()
        options = optparse.Values({'platform': None})
        logger, handler = lint_test_expectations.set_up_logging(logging_stream)
        try:
            res = lint_test_expectations.lint(host, options)
        finally:
            lint_test_expectations.tear_down_logging(logger, handler)
        self.assertEqual(res, 0)
        self.assertEqual(host.ports_parsed, ['a', 'b', 'b-win'])

    def test_lint_test_files(self):
        logging_stream = StringIO.StringIO()
        options = optparse.Values({'platform': 'test-mac-leopard'})
        host = MockHost()

        # pylint appears to complain incorrectly about the method overrides pylint: disable=E0202,C0322
        # FIXME: incorrect complaints about spacing pylint: disable=C0322
        host.port_factory.all_port_names = lambda platform=None: [platform]

        logger, handler = lint_test_expectations.set_up_logging(logging_stream)
        try:
            res = lint_test_expectations.lint(host, options)
            self.assertEqual(res, 0)
        finally:
            lint_test_expectations.tear_down_logging(logger, handler)


    def test_lint_test_files__errors(self):
        options = optparse.Values({'platform': 'test', 'debug_rwt_logging': False})
        host = MockHost()

        # FIXME: incorrect complaints about spacing pylint: disable=C0322
        port = host.port_factory.get(options.platform, options=options)
        port.expectations_dict = lambda: {'foo': '-- syntax error1', 'bar': '-- syntax error2'}

        host.port_factory.get = lambda platform, options=None: port
        host.port_factory.all_port_names = lambda platform=None: [port.name()]

        logging_stream = StringIO.StringIO()
        logger, handler = lint_test_expectations.set_up_logging(logging_stream)
        try:
            res = lint_test_expectations.lint(host, options)
        finally:
            lint_test_expectations.tear_down_logging(logger, handler)

        self.assertTrue(res)
        self.assertIn('foo:1', logging_stream.getvalue())
        self.assertIn('bar:1', logging_stream.getvalue())


class CheckVirtualSuiteTest(unittest.TestCase):
    def test_check_virtual_test_suites(self):
        host = MockHost()
        options = optparse.Values({'platform': 'test', 'debug_rwt_logging': False})
        orig_get = host.port_factory.get
        host.port_factory.get = lambda options: orig_get('test', options=options)

        logging_stream = StringIO.StringIO()
        logger, handler = lint_test_expectations.set_up_logging(logging_stream)
        try:
            res = lint_test_expectations.check_virtual_test_suites(host, options)
            self.assertTrue(res)

            host.filesystem.exists = lambda path: True
            res = lint_test_expectations.check_virtual_test_suites(host, options)
            self.assertFalse(res)
        finally:
            lint_test_expectations.tear_down_logging(logger, handler)


class MainTest(unittest.TestCase):
    # unused args pylint: disable=W0613

    def setUp(self):
        self.orig_lint_fn = lint_test_expectations.lint
        self.orig_check_fn = lint_test_expectations.check_virtual_test_suites
        lint_test_expectations.check_virtual_test_suites = lambda host, options: False

        self.stdout = StringIO.StringIO()
        self.stderr = StringIO.StringIO()

    def tearDown(self):
        lint_test_expectations.lint = self.orig_lint_fn
        lint_test_expectations.check_virtual_test_suites = self.orig_check_fn

    def test_success(self):
        lint_test_expectations.lint = lambda host, options: False
        res = lint_test_expectations.main(['--platform', 'test'], self.stdout, self.stderr)
        self.assertTrue('Lint succeeded' in self.stderr.getvalue())
        self.assertEqual(res, 0)

    def test_failure(self):
        lint_test_expectations.lint = lambda host, options: True
        res = lint_test_expectations.main(['--platform', 'test'], self.stdout, self.stderr)
        self.assertTrue('Lint failed' in self.stderr.getvalue())
        self.assertEqual(res, 1)

    def test_interrupt(self):
        def interrupting_lint(host, options):
            raise KeyboardInterrupt

        lint_test_expectations.lint = interrupting_lint
        res = lint_test_expectations.main([], self.stdout, self.stderr)
        self.assertEqual(res, lint_test_expectations.INTERRUPTED_EXIT_STATUS)

    def test_exception(self):
        def exception_raising_lint(host, options):
            assert False
        lint_test_expectations.lint = exception_raising_lint
        res = lint_test_expectations.main([], self.stdout, self.stderr)
        self.assertEqual(res, lint_test_expectations.EXCEPTIONAL_EXIT_STATUS)
