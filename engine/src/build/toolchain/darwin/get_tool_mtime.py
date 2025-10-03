#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


import os
import sys

# Usage: python get_tool_mtime.py path/to/file1.py path/to/file2.py
#
# Prints a GN scope with the variable name being the basename sans-extension
# and the value being the file modification time. A variable is emitted for
# each file argument on the command line.

if __name__ == '__main__':
  for f in sys.argv[1:]:
    variable = os.path.splitext(os.path.basename(f))[0]
    print('%s = %d' % (variable, os.path.getmtime(f)))
