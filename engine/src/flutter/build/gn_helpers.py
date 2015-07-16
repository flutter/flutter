# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Helper functions useful when writing scripts that are run from GN's
exec_script function."""

class GNException(Exception):
  pass


def ToGNString(value, allow_dicts = True):
  """Prints the given value to stdout.

  allow_dicts indicates if this function will allow converting dictionaries
  to GN scopes. This is only possible at the top level, you can't nest a
  GN scope in a list, so this should be set to False for recursive calls."""
  if isinstance(value, str):
    if value.find('\n') >= 0:
      raise GNException("Trying to print a string with a newline in it.")
    return '"' + value.replace('"', '\\"') + '"'

  if isinstance(value, list):
    return '[ %s ]' % ', '.join(ToGNString(v) for v in value)

  if isinstance(value, dict):
    if not allow_dicts:
      raise GNException("Attempting to recursively print a dictionary.")
    result = ""
    for key in value:
      if not isinstance(key, str):
        raise GNException("Dictionary key is not a string.")
      result += "%s = %s\n" % (key, ToGNString(value[key], False))
    return result

  if isinstance(value, int):
    return str(value)

  raise GNException("Unsupported type when printing to GN.")
