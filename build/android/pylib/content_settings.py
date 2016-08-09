# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from pylib import constants


class ContentSettings(dict):

  """A dict interface to interact with device content settings.

  System properties are key/value pairs as exposed by adb shell content.
  """

  def __init__(self, table, device):
    super(ContentSettings, self).__init__()
    self._table = table
    self._device = device

  @staticmethod
  def _GetTypeBinding(value):
    if isinstance(value, bool):
      return 'b'
    if isinstance(value, float):
      return 'f'
    if isinstance(value, int):
      return 'i'
    if isinstance(value, long):
      return 'l'
    if isinstance(value, str):
      return 's'
    raise ValueError('Unsupported type %s' % type(value))

  def iteritems(self):
    # Example row:
    # 'Row: 0 _id=13, name=logging_id2, value=-1fccbaa546705b05'
    for row in self._device.RunShellCommand(
        'content query --uri content://%s' % self._table, as_root=True):
      fields = row.split(', ')
      key = None
      value = None
      for field in fields:
        k, _, v = field.partition('=')
        if k == 'name':
          key = v
        elif k == 'value':
          value = v
      if not key:
        continue
      if not value:
        value = ''
      yield key, value

  def __getitem__(self, key):
    return self._device.RunShellCommand(
        'content query --uri content://%s --where "name=\'%s\'" '
        '--projection value' % (self._table, key), as_root=True).strip()

  def __setitem__(self, key, value):
    if key in self:
      self._device.RunShellCommand(
          'content update --uri content://%s '
          '--bind value:%s:%s --where "name=\'%s\'"' % (
              self._table,
              self._GetTypeBinding(value), value, key),
          as_root=True)
    else:
      self._device.RunShellCommand(
          'content insert --uri content://%s '
          '--bind name:%s:%s --bind value:%s:%s' % (
              self._table,
              self._GetTypeBinding(key), key,
              self._GetTypeBinding(value), value),
          as_root=True)

  def __delitem__(self, key):
    self._device.RunShellCommand(
        'content delete --uri content://%s '
        '--bind name:%s:%s' % (
            self._table,
            self._GetTypeBinding(key), key),
        as_root=True)
