#!/usr/bin/python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import sys
import os
import subprocess

sys.path.insert(1, '../../build')
from pyutil.file_util import symlink


def main(argv):
  parser = argparse.ArgumentParser()
  parser.add_argument('--symlink',
                      help='Whether to create a symlink in the buildroot to the SDK.')
  args = parser.parse_args()

  path = subprocess.check_output(['/usr/bin/env', 'xcode-select', '-p']).strip()
  path = os.path.join(path, "Toolchains", "XcodeDefault.xctoolchain")
  assert os.path.exists(path)

  if args.symlink:
    symlink_target = os.path.join(args.symlink, os.path.basename(path))
    symlink(path, symlink_target)
    path = symlink_target

  print(path)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
