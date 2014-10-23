# Copyright (C) 2011 Google Inc. All rights reserved.
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

"""Unit test for xcodeproj.py."""
import unittest

import xcodeproj


class TestErrorHandler(object):
    """Error handler for XcodeProjectFileChecker unittests"""
    def __init__(self, handler):
        self.handler = handler

    def turn_off_line_filtering(self):
        pass

    def __call__(self, line_number, category, confidence, message):
        self.handler(self, line_number, category, confidence, message)
        return True


class XcodeProjectFileCheckerTest(unittest.TestCase):
    """Tests XcodeProjectFileChecker class."""

    def assert_no_error(self, lines):
        def handler(error_handler, line_number, category, confidence, message):
            self.fail('Unexpected error: %d %s %d %s' % (line_number, category, confidence, message))

        error_handler = TestErrorHandler(handler)
        checker = xcodeproj.XcodeProjectFileChecker('', error_handler)
        checker.check(lines)

    def assert_error(self, lines, expected_message):
        self.had_error = False

        def handler(error_handler, line_number, category, confidence, message):
            self.assertEqual(expected_message, message)
            self.had_error = True
        error_handler = TestErrorHandler(handler)
        checker = xcodeproj.XcodeProjectFileChecker('', error_handler)
        checker.check(lines)
        self.assertTrue(self.had_error, '%s should have error: %s.' % (lines, expected_message))

    def test_detect_development_region(self):
        self.assert_no_error(['developmentRegion = English;'])
        self.assert_error([''], 'Missing "developmentRegion = English".')
        self.assert_error(['developmentRegion = Japanese;'],
                          'developmentRegion is not English.')
