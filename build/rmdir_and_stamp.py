#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Wipes out a directory recursively and then touches a stamp file.

This odd pairing of operations is used to support build scripts which
slurp up entire directories (e.g. build/android/javac.py when handling
generated sources) as inputs.

The general pattern of use is:

  - Add a target which generates |gen_sources| into |out_path| from |inputs|.
  - Include |stamp_file| as an input for that target or any of its rules which
    generate files in |out_path|.
  - Add an action which depends on |inputs| and which outputs |stamp_file|;
    the action should run this script and pass |out_path| and |stamp_file| as
    its arguments.

The net result is that you will force |out_path| to be wiped and all
|gen_sources| to be regenerated any time any file in |inputs| changes.

See //third_party/mojo/mojom_bindings_generator.gypi for an example use case.

"""

import errno
import os
import shutil
import sys


def Main(dst_dir, stamp_file):
  try:
    shutil.rmtree(os.path.normpath(dst_dir))
  except OSError as e:
    # Ignore only "not found" errors.
    if e.errno != errno.ENOENT:
      raise e
  with open(stamp_file, 'a'):
    os.utime(stamp_file, None)

if __name__ == '__main__':
  sys.exit(Main(sys.argv[1], sys.argv[2]))
