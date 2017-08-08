# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import subprocess
import sys

# This script returns the path to the SDK of the given type. Pass the type of
# SDK you want, which is typically "iphone" or "iphonesimulator".

if len(sys.argv) != 2:
  print "Takes one arg (SDK to find)"
  sys.exit(1)

command =  [
  'xcodebuild',
  '-version',
  '-sdk',
  sys.argv[1],
  'Path'
]

print subprocess.check_output(command).strip()
