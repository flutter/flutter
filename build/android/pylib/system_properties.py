# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class SystemProperties(dict):

  """A dict interface to interact with device system properties.

  System properties are key/value pairs as exposed by adb shell getprop/setprop.

  This implementation minimizes interaction with the physical device. It is
  valid for the lifetime of a boot.
  """

  def __init__(self, android_commands):
    super(SystemProperties, self).__init__()
    self._adb = android_commands
    self._cached_static_properties = {}

  def __getitem__(self, key):
    if self._IsStatic(key):
      if key not in self._cached_static_properties:
        self._cached_static_properties[key] = self._GetProperty(key)
      return self._cached_static_properties[key]
    return self._GetProperty(key)

  def __setitem__(self, key, value):
    # TODO(tonyg): This can fail with no root. Verify that it succeeds.
    self._adb.SendShellCommand('setprop %s "%s"' % (key, value), retry_count=3)

  @staticmethod
  def _IsStatic(key):
    # TODO(tonyg): This list is conservative and could be expanded as needed.
    return (key.startswith('ro.boot.') or
            key.startswith('ro.build.') or
            key.startswith('ro.product.'))

  def _GetProperty(self, key):
    return self._adb.SendShellCommand('getprop %s' % key, retry_count=3).strip()
