# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# pylint: disable=C0301
# Based on/taken from
#   http://code.activestate.com/recipes/578231-probably-the-fastest-memoization-decorator-in-the-/
# (with cosmetic changes).
# pylint: enable=C0301
def memoize(f):
  """Memoization decorator for a function taking a single argument."""
  class Memoize(dict):
    def __missing__(self, key):
      rv = self[key] = f(key)
      return rv
  return Memoize().__getitem__
