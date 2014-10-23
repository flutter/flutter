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

"""Checks WebKit style for test_expectations files."""

import logging
import optparse
import os
import re
import sys

from common import TabChecker
from webkitpy.common.host import Host
from webkitpy.layout_tests.models.test_expectations import TestExpectationParser


_log = logging.getLogger(__name__)


class TestExpectationsChecker(object):
    """Processes TestExpectations lines for validating the syntax."""

    categories = set(['test/expectations'])

    def __init__(self, file_path, handle_style_error, host=None):
        self._file_path = file_path
        self._handle_style_error = handle_style_error
        self._tab_checker = TabChecker(file_path, handle_style_error)

        # FIXME: host should be a required parameter, not an optional one.
        host = host or Host()
        host.initialize_scm()

        self._port_obj = host.port_factory.get()

        # Suppress error messages of test_expectations module since they will be reported later.
        log = logging.getLogger("webkitpy.layout_tests.layout_package.test_expectations")
        log.setLevel(logging.CRITICAL)

    def _handle_error_message(self, lineno, message, confidence):
        pass

    def check_test_expectations(self, expectations_str, tests=None):
        parser = TestExpectationParser(self._port_obj, tests, is_lint_mode=True)
        expectations = parser.parse('expectations', expectations_str)

        level = 5
        for expectation_line in expectations:
            for warning in expectation_line.warnings:
                self._handle_style_error(expectation_line.line_numbers, 'test/expectations', level, warning)

    def check_tabs(self, lines):
        self._tab_checker.check(lines)

    def check(self, lines):
        expectations = '\n'.join(lines)
        if self._port_obj:
            self.check_test_expectations(expectations_str=expectations, tests=None)

        # Warn tabs in lines as well
        self.check_tabs(lines)
