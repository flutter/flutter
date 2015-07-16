# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import errno
import os.path

def EnsureDirectoryExists(path, always_try_to_create=False):
  """A wrapper for os.makedirs that does not error if the directory already
  exists. A different process could be racing to create this directory."""

  if not os.path.exists(path) or always_try_to_create:
    try:
      os.makedirs(path)
    except OSError as e:
      # There may have been a race to create this directory.
      if e.errno != errno.EEXIST:
        raise
