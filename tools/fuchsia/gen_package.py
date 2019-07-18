#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Genrate a Fuchsia FAR Archive from an asset manifest and a signing key.
"""

import argparse
import collections
import json
import os
import subprocess
import sys

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--pm-bin', dest='pm_bin', action='store', required=True)
  parser.add_argument('--package-dir', dest='package_dir', action='store', required=True)
  parser.add_argument('--signing-key', dest='signing_key', action='store', required=True)
  parser.add_argument('--manifest-file', dest='manifest_file', action='store', required=True)

  args = parser.parse_args()

  assert os.path.exists(args.pm_bin)
  assert os.path.exists(args.package_dir)
  assert os.path.exists(args.signing_key)
  assert os.path.exists(args.manifest_file)

  pm_command_base = [
    args.pm_bin,
    '-o',
    args.package_dir,
    '-k',
    args.signing_key,
    '-m',
    args.manifest_file,
  ]

  # Build the package
  subprocess.check_call(pm_command_base + [ 'build' ]);

  # Archive the package
  subprocess.check_call(pm_command_base + [ 'archive' ]);

  return 0

if __name__ == '__main__':
  sys.exit(main())
