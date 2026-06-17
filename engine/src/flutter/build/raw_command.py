# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import subprocess


def main():
  if len(sys.argv) < 2:
    print("Usage: python3 raw_command.py <command> [args...]")
    return 1

  # Run the command directly, forwarding all arguments
  return subprocess.call(sys.argv[1:])


if __name__ == '__main__':
  sys.exit(main())
