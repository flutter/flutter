#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Simple script that executes the command supplied as arguments and pipes
# stderr/out through asan_symbolize.py.

import os
import subprocess
import sys

def main():
  p1 = subprocess.Popen(sys.argv[1:], stdout=subprocess.PIPE,
                        stderr=sys.stdout)
  p2 = subprocess.Popen([os.path.join('tools', 'valgrind', 'asan',
                                      'asan_symbolize.py')],
                        stdin=p1.stdout)
  p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.
  p1.wait()
  p2.wait()
  return p1.returncode


if __name__ == "__main__":
  sys.exit(main())
