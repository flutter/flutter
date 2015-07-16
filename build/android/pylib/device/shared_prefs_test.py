#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Unit tests for the contents of shared_prefs.py (mostly SharedPrefs).
"""

import logging
import os
import sys
import unittest

from pylib import constants
from pylib.device import device_utils
from pylib.device import shared_prefs

sys.path.append(os.path.join(
    constants.DIR_SOURCE_ROOT, 'third_party', 'pymock'))
import mock


def MockDeviceWithFiles(files=None):
  if files is None:
    files = {}

  def file_exists(path):
    return path in files

  def write_file(path, contents, **_kwargs):
    files[path] = contents

  def read_file(path, **_kwargs):
    return files[path]

  device = mock.MagicMock(spec=device_utils.DeviceUtils)
  device.FileExists = mock.Mock(side_effect=file_exists)
  device.WriteFile = mock.Mock(side_effect=write_file)
  device.ReadFile = mock.Mock(side_effect=read_file)
  return device


class SharedPrefsTest(unittest.TestCase):

  def setUp(self):
    self.device = MockDeviceWithFiles({
      '/data/data/com.some.package/shared_prefs/prefs.xml':
          "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n"
          '<map>\n'
          '  <int name="databaseVersion" value="107" />\n'
          '  <boolean name="featureEnabled" value="false" />\n'
          '  <string name="someHashValue">249b3e5af13d4db2</string>\n'
          '</map>'})
    self.expected_data = {'databaseVersion': 107,
                          'featureEnabled': False,
                          'someHashValue': '249b3e5af13d4db2'}

  def testPropertyLifetime(self):
    prefs = shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml')
    self.assertEquals(len(prefs), 0) # collection is empty before loading
    prefs.SetInt('myValue', 444)
    self.assertEquals(len(prefs), 1)
    self.assertEquals(prefs.GetInt('myValue'), 444)
    self.assertTrue(prefs.HasProperty('myValue'))
    prefs.Remove('myValue')
    self.assertEquals(len(prefs), 0)
    self.assertFalse(prefs.HasProperty('myValue'))
    with self.assertRaises(KeyError):
      prefs.GetInt('myValue')

  def testPropertyType(self):
    prefs = shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml')
    prefs.SetInt('myValue', 444)
    self.assertEquals(prefs.PropertyType('myValue'), 'int')
    with self.assertRaises(TypeError):
      prefs.GetString('myValue')
    with self.assertRaises(TypeError):
      prefs.SetString('myValue', 'hello')

  def testLoad(self):
    prefs = shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml')
    self.assertEquals(len(prefs), 0) # collection is empty before loading
    prefs.Load()
    self.assertEquals(len(prefs), len(self.expected_data))
    self.assertEquals(prefs.AsDict(), self.expected_data)
    self.assertFalse(prefs.changed)

  def testClear(self):
    prefs = shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml')
    prefs.Load()
    self.assertEquals(prefs.AsDict(), self.expected_data)
    self.assertFalse(prefs.changed)
    prefs.Clear()
    self.assertEquals(len(prefs), 0) # collection is empty now
    self.assertTrue(prefs.changed)

  def testCommit(self):
    prefs = shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'other_prefs.xml')
    self.assertFalse(self.device.FileExists(prefs.path)) # file does not exist
    prefs.Load()
    self.assertEquals(len(prefs), 0) # file did not exist, collection is empty
    prefs.SetInt('magicNumber', 42)
    prefs.SetFloat('myMetric', 3.14)
    prefs.SetLong('bigNumner', 6000000000)
    prefs.SetStringSet('apps', ['gmail', 'chrome', 'music'])
    self.assertFalse(self.device.FileExists(prefs.path)) # still does not exist
    self.assertTrue(prefs.changed)
    prefs.Commit()
    self.assertTrue(self.device.FileExists(prefs.path)) # should exist now
    self.device.KillAll.assert_called_once_with(prefs.package, as_root=True,
                                                quiet=True)
    self.assertFalse(prefs.changed)

    prefs = shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'other_prefs.xml')
    self.assertEquals(len(prefs), 0) # collection is empty before loading
    prefs.Load()
    self.assertEquals(prefs.AsDict(), {
        'magicNumber': 42,
        'myMetric': 3.14,
        'bigNumner': 6000000000,
        'apps': ['gmail', 'chrome', 'music']}) # data survived roundtrip

  def testAsContextManager_onlyReads(self):
    with shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml') as prefs:
      self.assertEquals(prefs.AsDict(), self.expected_data) # loaded and ready
    self.assertEquals(self.device.WriteFile.call_args_list, []) # did not write

  def testAsContextManager_readAndWrite(self):
    with shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml') as prefs:
      prefs.SetBoolean('featureEnabled', True)
      prefs.Remove('someHashValue')
      prefs.SetString('newString', 'hello')

    self.assertTrue(self.device.WriteFile.called) # did write
    with shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml') as prefs:
      # changes persisted
      self.assertTrue(prefs.GetBoolean('featureEnabled'))
      self.assertFalse(prefs.HasProperty('someHashValue'))
      self.assertEquals(prefs.GetString('newString'), 'hello')
      self.assertTrue(prefs.HasProperty('databaseVersion')) # still there

  def testAsContextManager_commitAborted(self):
    with self.assertRaises(TypeError):
      with shared_prefs.SharedPrefs(
          self.device, 'com.some.package', 'prefs.xml') as prefs:
        prefs.SetBoolean('featureEnabled', True)
        prefs.Remove('someHashValue')
        prefs.SetString('newString', 'hello')
        prefs.SetInt('newString', 123) # oops!

    self.assertEquals(self.device.WriteFile.call_args_list, []) # did not write
    with shared_prefs.SharedPrefs(
        self.device, 'com.some.package', 'prefs.xml') as prefs:
      # contents were not modified
      self.assertEquals(prefs.AsDict(), self.expected_data)

if __name__ == '__main__':
  logging.getLogger().setLevel(logging.DEBUG)
  unittest.main(verbosity=2)
