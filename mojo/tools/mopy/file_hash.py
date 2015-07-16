# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging

# pylint: disable=E0611
from hashlib import sha256

from mopy.memoize import memoize

_logging = logging.getLogger()

@memoize
def file_hash(filename):
  """Returns a string representing the hash of the given file."""
  _logging.debug("Hashing %s ...", filename)
  with open(filename, mode='rb') as f:
    m = sha256()
    while True:
      block = f.read(4096)
      if not block:
        break
      m.update(block)
  _logging.debug("  => %s", m.hexdigest())
  return m.hexdigest()
