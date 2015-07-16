# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for the contents of parallelizer.py."""

# pylint: disable=W0212
# pylint: disable=W0613

import os
import tempfile
import time
import unittest

from pylib.utils import parallelizer


class ParallelizerTestObject(object):
  """Class used to test parallelizer.Parallelizer."""

  parallel = parallelizer.Parallelizer

  def __init__(self, thing, completion_file_name=None):
    self._thing = thing
    self._completion_file_name = completion_file_name
    self.helper = ParallelizerTestObjectHelper(thing)

  @staticmethod
  def doReturn(what):
    return what

  @classmethod
  def doRaise(cls, what):
    raise what

  def doSetTheThing(self, new_thing):
    self._thing = new_thing

  def doReturnTheThing(self):
    return self._thing

  def doRaiseTheThing(self):
    raise self._thing

  def doRaiseIfExceptionElseSleepFor(self, sleep_duration):
    if isinstance(self._thing, Exception):
      raise self._thing
    time.sleep(sleep_duration)
    self._write_completion_file()
    return self._thing

  def _write_completion_file(self):
    if self._completion_file_name and len(self._completion_file_name):
      with open(self._completion_file_name, 'w+b') as completion_file:
        completion_file.write('complete')

  def __getitem__(self, index):
    return self._thing[index]

  def __str__(self):
    return type(self).__name__


class ParallelizerTestObjectHelper(object):

  def __init__(self, thing):
    self._thing = thing

  def doReturnStringThing(self):
    return str(self._thing)


class ParallelizerTest(unittest.TestCase):

  def testInitWithNone(self):
    with self.assertRaises(AssertionError):
      parallelizer.Parallelizer(None)

  def testInitEmptyList(self):
    with self.assertRaises(AssertionError):
      parallelizer.Parallelizer([])

  def testMethodCall(self):
    test_data = ['abc_foo', 'def_foo', 'ghi_foo']
    expected = ['abc_bar', 'def_bar', 'ghi_bar']
    r = parallelizer.Parallelizer(test_data).replace('_foo', '_bar').pGet(0.1)
    self.assertEquals(expected, r)

  def testMutate(self):
    devices = [ParallelizerTestObject(True) for _ in xrange(0, 10)]
    self.assertTrue(all(d.doReturnTheThing() for d in devices))
    ParallelizerTestObject.parallel(devices).doSetTheThing(False).pFinish(1)
    self.assertTrue(not any(d.doReturnTheThing() for d in devices))

  def testAllReturn(self):
    devices = [ParallelizerTestObject(True) for _ in xrange(0, 10)]
    results = ParallelizerTestObject.parallel(
        devices).doReturnTheThing().pGet(1)
    self.assertTrue(isinstance(results, list))
    self.assertEquals(10, len(results))
    self.assertTrue(all(results))

  def testAllRaise(self):
    devices = [ParallelizerTestObject(Exception('thing %d' % i))
               for i in xrange(0, 10)]
    p = ParallelizerTestObject.parallel(devices).doRaiseTheThing()
    with self.assertRaises(Exception):
      p.pGet(1)

  def testOneFailOthersComplete(self):
    parallel_device_count = 10
    exception_index = 7
    exception_msg = 'thing %d' % exception_index

    try:
      completion_files = [tempfile.NamedTemporaryFile(delete=False)
                          for _ in xrange(0, parallel_device_count)]
      devices = [
          ParallelizerTestObject(
              i if i != exception_index else Exception(exception_msg),
              completion_files[i].name)
          for i in xrange(0, parallel_device_count)]
      for f in completion_files:
        f.close()
      p = ParallelizerTestObject.parallel(devices)
      with self.assertRaises(Exception) as e:
        p.doRaiseIfExceptionElseSleepFor(2).pGet(3)
      self.assertTrue(exception_msg in str(e.exception))
      for i in xrange(0, parallel_device_count):
        with open(completion_files[i].name) as f:
          if i == exception_index:
            self.assertEquals('', f.read())
          else:
            self.assertEquals('complete', f.read())
    finally:
      for f in completion_files:
        os.remove(f.name)

  def testReusable(self):
    devices = [ParallelizerTestObject(True) for _ in xrange(0, 10)]
    p = ParallelizerTestObject.parallel(devices)
    results = p.doReturn(True).pGet(1)
    self.assertTrue(all(results))
    results = p.doReturn(True).pGet(1)
    self.assertTrue(all(results))
    with self.assertRaises(Exception):
      results = p.doRaise(Exception('reusableTest')).pGet(1)

  def testContained(self):
    devices = [ParallelizerTestObject(i) for i in xrange(0, 10)]
    results = (ParallelizerTestObject.parallel(devices).helper
        .doReturnStringThing().pGet(1))
    self.assertTrue(isinstance(results, list))
    self.assertEquals(10, len(results))
    for i in xrange(0, 10):
      self.assertEquals(str(i), results[i])

  def testGetItem(self):
    devices = [ParallelizerTestObject(range(i, i+10)) for i in xrange(0, 10)]
    results = ParallelizerTestObject.parallel(devices)[9].pGet(1)
    self.assertEquals(range(9, 19), results)


if __name__ == '__main__':
  unittest.main(verbosity=2)

