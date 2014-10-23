# Copyright (C) 2010 Chris Jerdonek (cjerdonek@webkit.org)
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Unit tests for common.py."""

import unittest

from common import CarriageReturnChecker
from common import TabChecker

# FIXME: The unit tests for the cpp, text, and common checkers should
#        share supporting test code. This can include, for example, the
#        mock style error handling code and the code to check that all
#        of a checker's categories are covered by the unit tests.
#        Such shared code can be located in a shared test file, perhaps
#        even this file.
class CarriageReturnCheckerTest(unittest.TestCase):

    """Tests check_no_carriage_return()."""

    _category = "whitespace/carriage_return"
    _confidence = 1
    _expected_message = ("One or more unexpected \\r (^M) found; "
                         "better to use only a \\n")

    def setUp(self):
        self._style_errors = [] # The list of accumulated style errors.

    def _mock_style_error_handler(self, line_number, category, confidence,
                                  message):
        """Append the error information to the list of style errors."""
        error = (line_number, category, confidence, message)
        self._style_errors.append(error)

    def assert_carriage_return(self, input_lines, expected_lines, error_lines):
        """Process the given line and assert that the result is correct."""
        handle_style_error = self._mock_style_error_handler

        checker = CarriageReturnChecker(handle_style_error)
        output_lines = checker.check(input_lines)

        # Check both the return value and error messages.
        self.assertEqual(output_lines, expected_lines)

        expected_errors = [(line_number, self._category, self._confidence,
                            self._expected_message)
                           for line_number in error_lines]
        self.assertEqual(self._style_errors, expected_errors)

    def test_ends_with_carriage(self):
        self.assert_carriage_return(["carriage return\r"],
                                    ["carriage return"],
                                    [1])

    def test_ends_with_nothing(self):
        self.assert_carriage_return(["no carriage return"],
                                    ["no carriage return"],
                                    [])

    def test_ends_with_newline(self):
        self.assert_carriage_return(["no carriage return\n"],
                                    ["no carriage return\n"],
                                    [])

    def test_carriage_in_middle(self):
        # The CarriageReturnChecker checks only the final character
        # of each line.
        self.assert_carriage_return(["carriage\r in a string"],
                                    ["carriage\r in a string"],
                                    [])

    def test_multiple_errors(self):
        self.assert_carriage_return(["line1", "line2\r", "line3\r"],
                                    ["line1", "line2", "line3"],
                                    [2, 3])


class TabCheckerTest(unittest.TestCase):

    """Tests for TabChecker."""

    def assert_tab(self, input_lines, error_lines):
        """Assert when the given lines contain tabs."""
        self._error_lines = []

        def style_error_handler(line_number, category, confidence, message):
            self.assertEqual(category, 'whitespace/tab')
            self.assertEqual(confidence, 5)
            self.assertEqual(message, 'Line contains tab character.')
            self._error_lines.append(line_number)

        checker = TabChecker('', style_error_handler)
        checker.check(input_lines)
        self.assertEqual(self._error_lines, error_lines)

    def test_notab(self):
        self.assert_tab([''], [])
        self.assert_tab(['foo', 'bar'], [])

    def test_tab(self):
        self.assert_tab(['\tfoo'], [1])
        self.assert_tab(['line1', '\tline2', 'line3\t'], [2, 3])
