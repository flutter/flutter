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

SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))
ANDROID_HOME = os.path.join(SCRIPT_PATH, '..', '..', '..', '..', 'third_party',
    'android_tools', 'sdk')

def main():
  if not os.path.isdir(ANDROID_HOME):
    raise Exception('%s (ANDROID_HOME) is not a directory' % ANDROID_HOME)

  BAT = '.bat' if sys.platform.startswith(('cygwin', 'win')) else ''
  android_dir = os.path.abspath(os.path.dirname(__file__))
  gradle_bin = os.path.join('.', 'gradlew%s' % BAT)
  result = subprocess.check_output(
    args=[gradle_bin] + sys.argv[1:],
    cwd=android_dir,
    env=dict(os.environ, ANDROID_HOME=ANDROID_HOME),
  )
  return 0


if __name__ == '__main__':
  sys.exit(main())
