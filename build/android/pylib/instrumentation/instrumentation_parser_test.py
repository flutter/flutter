#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


"""Unit tests for instrumentation.InstrumentationParser."""

import unittest

from pylib.instrumentation import instrumentation_parser


class InstrumentationParserTest(unittest.TestCase):

  def testInstrumentationParser_nothing(self):
    parser = instrumentation_parser.InstrumentationParser([''])
    statuses = list(parser.IterStatus())
    code, bundle = parser.GetResult()
    self.assertEqual(None, code)
    self.assertEqual({}, bundle)
    self.assertEqual([], statuses)

  def testInstrumentationParser_noMatchingStarts(self):
    raw_output = [
      '',
      'this.is.a.test.package.TestClass:.',
      'Test result for =.',
      'Time: 1.234',
      '',
      'OK (1 test)',
    ]

    parser = instrumentation_parser.InstrumentationParser(raw_output)
    statuses = list(parser.IterStatus())
    code, bundle = parser.GetResult()
    self.assertEqual(None, code)
    self.assertEqual({}, bundle)
    self.assertEqual([], statuses)

  def testInstrumentationParser_resultAndCode(self):
    raw_output = [
      'INSTRUMENTATION_RESULT: shortMsg=foo bar',
      'INSTRUMENTATION_RESULT: longMsg=a foo',
      'walked into',
      'a bar',
      'INSTRUMENTATION_CODE: -1',
    ]

    parser = instrumentation_parser.InstrumentationParser(raw_output)
    statuses = list(parser.IterStatus())
    code, bundle = parser.GetResult()
    self.assertEqual(-1, code)
    self.assertEqual(
        {'shortMsg': 'foo bar', 'longMsg': 'a foo\nwalked into\na bar'}, bundle)
    self.assertEqual([], statuses)

  def testInstrumentationParser_oneStatus(self):
    raw_output = [
      'INSTRUMENTATION_STATUS: foo=1',
      'INSTRUMENTATION_STATUS: bar=hello',
      'INSTRUMENTATION_STATUS: world=false',
      'INSTRUMENTATION_STATUS: class=this.is.a.test.package.TestClass',
      'INSTRUMENTATION_STATUS: test=testMethod',
      'INSTRUMENTATION_STATUS_CODE: 0',
    ]

    parser = instrumentation_parser.InstrumentationParser(raw_output)
    statuses = list(parser.IterStatus())

    expected = [
      (0, {
        'foo': '1',
        'bar': 'hello',
        'world': 'false',
        'class': 'this.is.a.test.package.TestClass',
        'test': 'testMethod',
      })
    ]
    self.assertEqual(expected, statuses)

  def testInstrumentationParser_multiStatus(self):
    raw_output = [
      'INSTRUMENTATION_STATUS: class=foo',
      'INSTRUMENTATION_STATUS: test=bar',
      'INSTRUMENTATION_STATUS_CODE: 1',
      'INSTRUMENTATION_STATUS: test_skipped=true',
      'INSTRUMENTATION_STATUS_CODE: 0',
      'INSTRUMENTATION_STATUS: class=hello',
      'INSTRUMENTATION_STATUS: test=world',
      'INSTRUMENTATION_STATUS: stack=',
      'foo/bar.py (27)',
      'hello/world.py (42)',
      'test/file.py (1)',
      'INSTRUMENTATION_STATUS_CODE: -1',
    ]

    parser = instrumentation_parser.InstrumentationParser(raw_output)
    statuses = list(parser.IterStatus())

    expected = [
      (1, {'class': 'foo', 'test': 'bar',}),
      (0, {'test_skipped': 'true'}),
      (-1, {
        'class': 'hello',
        'test': 'world',
        'stack': '\nfoo/bar.py (27)\nhello/world.py (42)\ntest/file.py (1)',
      }),
    ]
    self.assertEqual(expected, statuses)

  def testInstrumentationParser_statusResultAndCode(self):
    raw_output = [
      'INSTRUMENTATION_STATUS: class=foo',
      'INSTRUMENTATION_STATUS: test=bar',
      'INSTRUMENTATION_STATUS_CODE: 1',
      'INSTRUMENTATION_RESULT: result=hello',
      'world',
      '',
      '',
      'INSTRUMENTATION_CODE: 0',
    ]

    parser = instrumentation_parser.InstrumentationParser(raw_output)
    statuses = list(parser.IterStatus())
    code, bundle = parser.GetResult()

    self.assertEqual(0, code)
    self.assertEqual({'result': 'hello\nworld\n\n'}, bundle)
    self.assertEqual([(1, {'class': 'foo', 'test': 'bar'})], statuses)


if __name__ == '__main__':
  unittest.main(verbosity=2)
