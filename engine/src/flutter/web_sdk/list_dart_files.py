#!/usr/bin/env python3
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tool for listing Dart source files.

If the first argument is 'relative', the script produces paths relative to the
current working directory. If the first argument is 'absolute', the script
produces absolute paths.

Usage:
  python3 tools/list_dart_files.py {absolute, relative} <directory> <pattern>
"""

import os
import re
import sys


def main(argv):
  mode = argv[1]
  if mode not in ['absolute', 'relative']:
    raise Exception("First argument must be 'absolute' or 'relative'")
  directory = argv[2]
  if mode in 'absolute' and not os.path.isabs(directory):
    directory = os.path.realpath(directory)

  pattern = None
  if len(argv) > 3:
    pattern = re.compile(argv[3])

  for root, directories, files in os.walk(directory):
    # We only care about actual source files, not generated code or tests.
    for skip_dir in ['.git', 'gen', 'test']:
      if skip_dir in directories:
        directories.remove(skip_dir)

    # If we are looking at the root directory, filter the immediate
    # subdirectories by the given pattern.
    if pattern and root == directory:
      directories[:] = filter(pattern.match, directories)

    for filename in files:
      if filename.endswith('.dart') and not filename.endswith('_test.dart'):
        if mode in 'absolute':
          fullname = os.path.join(directory, root, filename)
        else:
          fullname = os.path.relpath(os.path.join(root, filename))
        fullname = fullname.replace(os.sep, '/')
        print(fullname)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
