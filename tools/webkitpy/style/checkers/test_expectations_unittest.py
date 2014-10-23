# Copyright (C) 2010 Google Inc. All rights reserved.
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

import os
import sys
import unittest

from test_expectations import TestExpectationsChecker
from webkitpy.common.host_mock import MockHost


class ErrorCollector(object):
    """An error handler class for unit tests."""

    def __init__(self):
        self._errors = []
        self.turned_off_filtering = False

    def turn_off_line_filtering(self):
        self.turned_off_filtering = True

    def __call__(self, lineno, category, confidence, message):
        self._errors.append('%s  [%s] [%d]' % (message, category, confidence))
        return True

    def get_errors(self):
        return ''.join(self._errors)

    def reset_errors(self):
        self._errors = []
        self.turned_off_filtering = False


class TestExpectationsTestCase(unittest.TestCase):
    """TestCase for test_expectations.py"""

    def setUp(self):
        self._error_collector = ErrorCollector()
        self._test_file = 'passes/text.html'

    def assert_lines_lint(self, lines, should_pass, expected_output=None):
        self._error_collector.reset_errors()

        host = MockHost()
        checker = TestExpectationsChecker('test/TestExpectations',
                                          self._error_collector, host=host)

        # We should have a valid port, but override it with a test port so we
        # can check the lines.
        self.assertIsNotNone(checker._port_obj)
        checker._port_obj = host.port_factory.get('test-mac-leopard')

        checker.check_test_expectations(expectations_str='\n'.join(lines),
                                        tests=[self._test_file])
        checker.check_tabs(lines)
        if should_pass:
            self.assertEqual('', self._error_collector.get_errors())
        elif expected_output:
            self.assertEqual(expected_output, self._error_collector.get_errors())
        else:
            self.assertNotEquals('', self._error_collector.get_errors())

        # Note that a patch might change a line that introduces errors elsewhere, but we
        # don't want to lint the whole file (it can unfairly punish patches for pre-existing errors).
        # We rely on a separate lint-webkitpy step on the bots to keep the whole file okay.
        # FIXME: See https://bugs.webkit.org/show_bug.cgi?id=104712 .
        self.assertFalse(self._error_collector.turned_off_filtering)

    def test_valid_expectations(self):
        self.assert_lines_lint(["crbug.com/1234 [ Mac ] passes/text.html [ Pass Failure ]"], should_pass=True)

    def test_invalid_expectations(self):
        self.assert_lines_lint(["Bug(me) passes/text.html [ Give Up]"], should_pass=False)

    def test_tab(self):
        self.assert_lines_lint(["\twebkit.org/b/1 passes/text.html [ Pass ]"], should_pass=False, expected_output="Line contains tab character.  [whitespace/tab] [5]")
