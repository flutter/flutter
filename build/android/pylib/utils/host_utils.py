# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os


def GetRecursiveDiskUsage(path):
  """Returns the disk usage in bytes of |path|. Similar to `du -sb |path|`."""
  running_size = os.path.getsize(path)
  if os.path.isdir(path):
    for root, dirs, files in os.walk(path):
      running_size += sum([os.path.getsize(os.path.join(root, f))
                           for f in files + dirs])
  return running_size

