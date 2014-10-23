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

"""Unit tests for error_handlers.py."""

import unittest

from checker import StyleProcessorConfiguration
from error_handlers import DefaultStyleErrorHandler
from filter import FilterConfiguration


class DefaultStyleErrorHandlerTest(unittest.TestCase):

    """Tests the DefaultStyleErrorHandler class."""

    def setUp(self):
        self._error_messages = []
        self._error_count = 0

    _category = "whitespace/tab"
    """The category name for the tests in this class."""

    _file_path = "foo.h"
    """The file path for the tests in this class."""

    def _mock_increment_error_count(self):
        self._error_count += 1

    def _mock_stderr_write(self, message):
        self._error_messages.append(message)

    def _style_checker_configuration(self):
        """Return a StyleProcessorConfiguration instance for testing."""
        base_rules = ["-whitespace", "+whitespace/tab"]
        filter_configuration = FilterConfiguration(base_rules=base_rules)

        return StyleProcessorConfiguration(
                   filter_configuration=filter_configuration,
                   max_reports_per_category={"whitespace/tab": 2},
                   min_confidence=3,
                   output_format="vs7",
                   stderr_write=self._mock_stderr_write)

    def _error_handler(self, configuration, line_numbers=None):
        return DefaultStyleErrorHandler(configuration=configuration,
                   file_path=self._file_path,
                   increment_error_count=self._mock_increment_error_count,
                   line_numbers=line_numbers)

    def _check_initialized(self):
        """Check that count and error messages are initialized."""
        self.assertEqual(0, self._error_count)
        self.assertEqual(0, len(self._error_messages))

    def _call_error_handler(self, handle_error, confidence, line_number=100):
        """Call the given error handler with a test error."""
        handle_error(line_number=line_number,
                     category=self._category,
                     confidence=confidence,
                     message="message")

    def test_eq__true_return_value(self):
        """Test the __eq__() method for the return value of True."""
        handler1 = self._error_handler(configuration=None)
        handler2 = self._error_handler(configuration=None)

        self.assertTrue(handler1.__eq__(handler2))

    def test_eq__false_return_value(self):
        """Test the __eq__() method for the return value of False."""
        def make_handler(configuration=self._style_checker_configuration(),
                file_path='foo.txt', increment_error_count=lambda: True,
                line_numbers=[100]):
            return DefaultStyleErrorHandler(configuration=configuration,
                       file_path=file_path,
                       increment_error_count=increment_error_count,
                       line_numbers=line_numbers)

        handler = make_handler()

        # Establish a baseline for our comparisons below.
        self.assertTrue(handler.__eq__(make_handler()))

        # Verify that a difference in any argument causes equality to fail.
        self.assertFalse(handler.__eq__(make_handler(configuration=None)))
        self.assertFalse(handler.__eq__(make_handler(file_path='bar.txt')))
        self.assertFalse(handler.__eq__(make_handler(increment_error_count=None)))
        self.assertFalse(handler.__eq__(make_handler(line_numbers=[50])))

    def test_ne(self):
        """Test the __ne__() method."""
        # By default, __ne__ always returns true on different objects.
        # Thus, check just the distinguishing case to verify that the
        # code defines __ne__.
        handler1 = self._error_handler(configuration=None)
        handler2 = self._error_handler(configuration=None)

        self.assertFalse(handler1.__ne__(handler2))

    def test_non_reportable_error(self):
        """Test __call__() with a non-reportable error."""
        self._check_initialized()
        configuration = self._style_checker_configuration()

        confidence = 1
        # Confirm the error is not reportable.
        self.assertFalse(configuration.is_reportable(self._category,
                                                     confidence,
                                                     self._file_path))
        error_handler = self._error_handler(configuration)
        self._call_error_handler(error_handler, confidence)

        self.assertEqual(0, self._error_count)
        self.assertEqual([], self._error_messages)

    # Also serves as a reportable error test.
    def test_max_reports_per_category(self):
        """Test error report suppression in __call__() method."""
        self._check_initialized()
        configuration = self._style_checker_configuration()
        error_handler = self._error_handler(configuration)

        confidence = 5

        # First call: usual reporting.
        self._call_error_handler(error_handler, confidence)
        self.assertEqual(1, self._error_count)
        self.assertEqual(1, len(self._error_messages))
        self.assertEqual(self._error_messages,
                          ["foo.h(100):  message  [whitespace/tab] [5]\n"])

        # Second call: suppression message reported.
        self._call_error_handler(error_handler, confidence)
        # The "Suppressing further..." message counts as an additional
        # message (but not as an addition to the error count).
        self.assertEqual(2, self._error_count)
        self.assertEqual(3, len(self._error_messages))
        self.assertEqual(self._error_messages[-2],
                          "foo.h(100):  message  [whitespace/tab] [5]\n")
        self.assertEqual(self._error_messages[-1],
                          "Suppressing further [whitespace/tab] reports "
                          "for this file.\n")

        # Third call: no report.
        self._call_error_handler(error_handler, confidence)
        self.assertEqual(3, self._error_count)
        self.assertEqual(3, len(self._error_messages))

    def test_line_numbers(self):
        """Test the line_numbers parameter."""
        self._check_initialized()
        configuration = self._style_checker_configuration()
        error_handler = self._error_handler(configuration,
                                            line_numbers=[50])
        confidence = 5

        # Error on non-modified line: no error.
        self._call_error_handler(error_handler, confidence, line_number=60)
        self.assertEqual(0, self._error_count)
        self.assertEqual([], self._error_messages)

        # Error on modified line: error.
        self._call_error_handler(error_handler, confidence, line_number=50)
        self.assertEqual(1, self._error_count)
        self.assertEqual(self._error_messages,
                          ["foo.h(50):  message  [whitespace/tab] [5]\n"])

        # Error on non-modified line after turning off line filtering: error.
        error_handler.turn_off_line_filtering()
        self._call_error_handler(error_handler, confidence, line_number=60)
        self.assertEqual(2, self._error_count)
        self.assertEqual(self._error_messages,
                          ['foo.h(50):  message  [whitespace/tab] [5]\n',
                           'foo.h(60):  message  [whitespace/tab] [5]\n',
                           'Suppressing further [whitespace/tab] reports for this file.\n'])
