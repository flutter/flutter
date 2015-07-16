# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the Microsoft Message Compiler (mc.exe). This Python adapter is for the
# GN build, which can only run Python and not native binaries.

import subprocess
import sys

# mc writes to stderr, so this explicily redirects to stdout and eats it.
try:
  subprocess.check_output(["mc.exe"] + sys.argv[1:], stderr=subprocess.STDOUT)
except subprocess.CalledProcessError as e:
  print e.output
  sys.exit(e.returncode)
