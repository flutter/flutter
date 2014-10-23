# Copyright (C) 2010 Apple Inc. All rights reserved.
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
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Unit test for xml.py."""

import unittest
import xml


class MockErrorHandler(object):
    def __init__(self, handle_style_error):
        self.turned_off_filtering = False
        self._handle_style_error = handle_style_error

    def turn_off_line_filtering(self):
        self.turned_off_filtering = True

    def __call__(self, line_number, category, confidence, message):
        self._handle_style_error(self, line_number, category, confidence, message)
        return True


class XMLCheckerTest(unittest.TestCase):
    """Tests XMLChecker class."""

    def assert_no_error(self, xml_data):
        def handle_style_error(mock_error_handler, line_number, category, confidence, message):
            self.fail('Unexpected error: %d %s %d %s' % (line_number, category, confidence, message))

        error_handler = MockErrorHandler(handle_style_error)
        checker = xml.XMLChecker('foo.xml', error_handler)
        checker.check(xml_data.split('\n'))
        self.assertTrue(error_handler.turned_off_filtering)

    def assert_error(self, expected_line_number, expected_category, xml_data):
        def handle_style_error(mock_error_handler, line_number, category, confidence, message):
            mock_error_handler.had_error = True
            self.assertEqual(expected_line_number, line_number)
            self.assertEqual(expected_category, category)

        error_handler = MockErrorHandler(handle_style_error)
        error_handler.had_error = False

        checker = xml.XMLChecker('foo.xml', error_handler)
        checker.check(xml_data.split('\n'))
        self.assertTrue(error_handler.had_error)
        self.assertTrue(error_handler.turned_off_filtering)

    def mock_handle_style_error(self):
        pass

    def test_conflict_marker(self):
        self.assert_error(1, 'xml/syntax', '<<<<<<< HEAD\n<foo>\n</foo>\n')

    def test_extra_closing_tag(self):
        self.assert_error(3, 'xml/syntax', '<foo>\n</foo>\n</foo>\n')

    def test_init(self):
        error_handler = MockErrorHandler(self.mock_handle_style_error)
        checker = xml.XMLChecker('foo.xml', error_handler)
        self.assertEqual(checker._handle_style_error, error_handler)

    def test_missing_closing_tag(self):
        self.assert_error(3, 'xml/syntax', '<foo>\n<bar>\n</foo>\n')

    def test_no_error(self):
        self.assert_no_error('<foo>\n</foo>')
