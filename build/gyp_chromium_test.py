#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys
import unittest

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
SRC_DIR = os.path.dirname(SCRIPT_DIR)

sys.path.append(os.path.join(SRC_DIR, 'third_party', 'pymock'))

import mock

# TODO(sbc): Make gyp_chromium more testable by putting the code in
# a .py file.
gyp_chromium = __import__('gyp_chromium')


class TestGetOutputDirectory(unittest.TestCase):
  @mock.patch('os.environ', {})
  @mock.patch('sys.argv', [__file__])
  def testDefaultValue(self):
    self.assertEqual(gyp_chromium.GetOutputDirectory(), 'out')

  @mock.patch('os.environ', {'GYP_GENERATOR_FLAGS': 'output_dir=envfoo'})
  @mock.patch('sys.argv', [__file__])
  def testEnvironment(self):
    self.assertEqual(gyp_chromium.GetOutputDirectory(), 'envfoo')

  @mock.patch('os.environ', {'GYP_GENERATOR_FLAGS': 'output_dir=envfoo'})
  @mock.patch('sys.argv', [__file__, '-Goutput_dir=cmdfoo'])
  def testGFlagOverridesEnv(self):
    self.assertEqual(gyp_chromium.GetOutputDirectory(), 'cmdfoo')

  @mock.patch('os.environ', {})
  @mock.patch('sys.argv', [__file__, '-G', 'output_dir=foo'])
  def testGFlagWithSpace(self):
    self.assertEqual(gyp_chromium.GetOutputDirectory(), 'foo')


class TestGetGypVars(unittest.TestCase):
  @mock.patch('os.environ', {})
  def testDefault(self):
    self.assertEqual(gyp_chromium.GetGypVars([]), {})

  @mock.patch('os.environ', {})
  @mock.patch('sys.argv', [__file__, '-D', 'foo=bar'])
  def testDFlags(self):
    self.assertEqual(gyp_chromium.GetGypVars([]), {'foo': 'bar'})

  @mock.patch('os.environ', {})
  @mock.patch('sys.argv', [__file__, '-D', 'foo'])
  def testDFlagsNoValue(self):
    self.assertEqual(gyp_chromium.GetGypVars([]), {'foo': '1'})

  @mock.patch('os.environ', {})
  @mock.patch('sys.argv', [__file__, '-D', 'foo=bar', '-Dbaz'])
  def testDFlagMulti(self):
    self.assertEqual(gyp_chromium.GetGypVars([]), {'foo': 'bar', 'baz': '1'})


if __name__ == '__main__':
  unittest.main()
