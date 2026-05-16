#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--clang', required=True, help='Path to clang binary')
  args = parser.parse_args()

  try:
    output = subprocess.check_output([args.clang, '-print-runtime-dir'], text=True).strip()
    print(output)
    return 0
  except subprocess.CalledProcessError as e:
    sys.stderr.write(f"Error running clang: {e}\n")
    return 1

if __name__ == '__main__':
  sys.exit(main())
