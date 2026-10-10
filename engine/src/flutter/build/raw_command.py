# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Executes a command and its arguments directly via subprocess.

In GN build actions (particularly on Windows), invoking binaries with complex
command-line flags or paths through standard GN actions can be subject to shell
interpretation and escaping quirks. This script provides a minimal, shell-agnostic
entry point to execute commands directly.
"""

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
