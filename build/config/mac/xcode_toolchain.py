#!/usr/bin/python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import os
import subprocess

def Main():
  path = subprocess.check_output(['/usr/bin/env', 'xcode-select', '-p']).strip();
  path = os.path.join(path, "Toolchains", "XcodeDefault.xctoolchain")
  assert os.path.exists(path)
  print path

if __name__ == '__main__':
  sys.exit(Main())
