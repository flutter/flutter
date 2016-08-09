# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for the cmd_helper module."""

import unittest
import subprocess

from pylib import cmd_helper


class CmdHelperSingleQuoteTest(unittest.TestCase):

  def testSingleQuote_basic(self):
    self.assertEquals('hello',
                      cmd_helper.SingleQuote('hello'))

  def testSingleQuote_withSpaces(self):
    self.assertEquals("'hello world'",
                      cmd_helper.SingleQuote('hello world'))

  def testSingleQuote_withUnsafeChars(self):
    self.assertEquals("""'hello'"'"'; rm -rf /'""",
                      cmd_helper.SingleQuote("hello'; rm -rf /"))

  def testSingleQuote_dontExpand(self):
    test_string = 'hello $TEST_VAR'
    cmd = 'TEST_VAR=world; echo %s' % cmd_helper.SingleQuote(test_string)
    self.assertEquals(test_string,
                      cmd_helper.GetCmdOutput(cmd, shell=True).rstrip())


class CmdHelperDoubleQuoteTest(unittest.TestCase):

  def testDoubleQuote_basic(self):
    self.assertEquals('hello',
                      cmd_helper.DoubleQuote('hello'))

  def testDoubleQuote_withSpaces(self):
    self.assertEquals('"hello world"',
                      cmd_helper.DoubleQuote('hello world'))

  def testDoubleQuote_withUnsafeChars(self):
    self.assertEquals('''"hello\\"; rm -rf /"''',
                      cmd_helper.DoubleQuote('hello"; rm -rf /'))

  def testSingleQuote_doExpand(self):
    test_string = 'hello $TEST_VAR'
    cmd = 'TEST_VAR=world; echo %s' % cmd_helper.DoubleQuote(test_string)
    self.assertEquals('hello world',
                      cmd_helper.GetCmdOutput(cmd, shell=True).rstrip())


class CmdHelperIterCmdOutputLinesTest(unittest.TestCase):
  """Test IterCmdOutputLines with some calls to the unix 'seq' command."""

  def testIterCmdOutputLines_success(self):
    for num, line in enumerate(
        cmd_helper.IterCmdOutputLines(['seq', '10']), 1):
      self.assertEquals(num, int(line))

  def testIterCmdOutputLines_exitStatusFail(self):
    with self.assertRaises(subprocess.CalledProcessError):
      for num, line in enumerate(
          cmd_helper.IterCmdOutputLines('seq 10 && false', shell=True), 1):
        self.assertEquals(num, int(line))
      # after reading all the output we get an exit status of 1

  def testIterCmdOutputLines_exitStatusIgnored(self):
    for num, line in enumerate(
        cmd_helper.IterCmdOutputLines('seq 10 && false', shell=True,
                                      check_status=False), 1):
      self.assertEquals(num, int(line))

  def testIterCmdOutputLines_exitStatusSkipped(self):
    for num, line in enumerate(
        cmd_helper.IterCmdOutputLines('seq 10 && false', shell=True), 1):
      self.assertEquals(num, int(line))
      # no exception will be raised because we don't attempt to read past
      # the end of the output and, thus, the status never gets checked
      if num == 10:
        break
