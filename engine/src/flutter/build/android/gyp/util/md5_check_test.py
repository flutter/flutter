# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import tempfile
import unittest

import md5_check # pylint: disable=W0403


class TestMd5Check(unittest.TestCase):
  def setUp(self):
    self.called = False

  def testCallAndRecordIfStale(self):
    input_strings = ['string1', 'string2']
    input_file1 = tempfile.NamedTemporaryFile()
    input_file2 = tempfile.NamedTemporaryFile()
    file1_contents = 'input file 1'
    file2_contents = 'input file 2'
    input_file1.write(file1_contents)
    input_file1.flush()
    input_file2.write(file2_contents)
    input_file2.flush()
    input_files = [input_file1.name, input_file2.name]

    record_path = tempfile.NamedTemporaryFile(suffix='.stamp')

    def CheckCallAndRecord(should_call, message, force=False):
      self.called = False
      def MarkCalled():
        self.called = True
      md5_check.CallAndRecordIfStale(
          MarkCalled,
          record_path=record_path.name,
          input_paths=input_files,
          input_strings=input_strings,
          force=force)
      self.failUnlessEqual(should_call, self.called, message)

    CheckCallAndRecord(True, 'should call when record doesn\'t exist')
    CheckCallAndRecord(False, 'should not call when nothing changed')
    CheckCallAndRecord(True, force=True, message='should call when forced')

    input_file1.write('some more input')
    input_file1.flush()
    CheckCallAndRecord(True, 'changed input file should trigger call')

    input_files = input_files[::-1]
    CheckCallAndRecord(False, 'reordering of inputs shouldn\'t trigger call')

    input_files = input_files[:1]
    CheckCallAndRecord(True, 'removing file should trigger call')

    input_files.append(input_file2.name)
    CheckCallAndRecord(True, 'added input file should trigger call')

    input_strings[0] = input_strings[0] + ' a bit longer'
    CheckCallAndRecord(True, 'changed input string should trigger call')

    input_strings = input_strings[::-1]
    CheckCallAndRecord(True, 'reordering of string inputs should trigger call')

    input_strings = input_strings[:1]
    CheckCallAndRecord(True, 'removing a string should trigger call')

    input_strings.append('a brand new string')
    CheckCallAndRecord(True, 'added input string should trigger call')


if __name__ == '__main__':
  unittest.main()
