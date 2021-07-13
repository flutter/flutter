#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Invokes gradlew for building the scenario_app from GN/Ninja.
"""

import os
import sys
import subprocess

def main():
  BAT = '.bat' if sys.platform.startswith(('cygwin', 'win')) else ''
  android_dir = os.path.abspath(os.path.dirname(__file__))
  gradle_bin = os.path.join('.', 'gradlew%s' % BAT)
  result = subprocess.check_output(
    args=[gradle_bin] + sys.argv[1:],
    cwd=android_dir,
  )
  return 0


if __name__ == '__main__':
  sys.exit(main())
