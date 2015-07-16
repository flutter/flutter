# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

from webkitpy.layout_tests.models import testharness_results


class TestHarnessResultCheckerTest(unittest.TestCase):

    def test_is_testharness_output(self):
        test_data = [
            {'content': 'foo', 'result': False},
            {'content': '', 'result': False},
            {'content': '   ', 'result': False},
            {'content': 'This is a testharness.js-based test.\nHarness: the test ran to completion.', 'result': True},
            {'content': '\n \r This is a testharness.js-based test. \n \r  \n \rHarness: the test ran to completion.   \n\n', 'result': True},
            {'content': '   This    \nis a testharness.js-based test.\nHarness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.  Harness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.\nFoo bar \n Harness: the test ran to completion.', 'result': True},
            {'content': 'This is a testharness.js-based test.\nFAIL: bah \n Harness: the test ran to completion.\n\n\n', 'result': True},
        ]

        for data in test_data:
            self.assertEqual(data['result'], testharness_results.is_testharness_output(data['content']))

    def test_is_testharness_output_passing(self):
        test_data = [
            {'content': 'This is a testharness.js-based test.\n   Harness: the test ran to completion.', 'result': True},
            {'content': 'This is a testharness.js-based test.\n  \n Harness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.\n PASS: foo bar \n Harness: the test ran to completion.', 'result': True},
            {'content': 'This is a testharness.js-based test.\n PASS: foo bar FAIL  \n Harness: the test ran to completion.', 'result': True},
            {'content': 'This is a testharness.js-based test.\n PASS: foo bar \nFAIL  \n Harness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.\n CONSOLE ERROR: BLAH  \n Harness: the test ran to completion.', 'result': True},
            {'content': 'This is a testharness.js-based test.\n Foo bar \n Harness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.\n FAIL: bah \n Harness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.\n TIMEOUT: bah \n Harness: the test ran to completion.', 'result': False},
            {'content': 'This is a testharness.js-based test.\n NOTRUN: bah \n Harness: the test ran to completion.', 'result': False},
            {'content': 'CONSOLE LOG: error.\nThis is a testharness.js-based test.\nPASS: things are fine.\nHarness: the test ran to completion.\n\n', 'result': True},
            {'content': 'CONSOLE ERROR: error.\nThis is a testharness.js-based test.\nPASS: things are fine.\nHarness: the test ran to completion.\n\n', 'result': True},
            {'content': 'RANDOM TEXT.\nThis is a testharness.js-based test.\nPASS: things are fine.\n.Harness: the test ran to completion.\n\n', 'result': False},
        ]

        for data in test_data:
            self.assertEqual(data['result'], testharness_results.is_testharness_output_passing(data['content']))
