#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
mass-rename: update source files (gyp lists, #includes) to reflect
a rename.  Expects "git diff --cached -M" to list a bunch of renames.

To use:
  1) git mv foo1 bar1; git mv foo2 bar2; etc.
  2) *without committing*, ./tools/git/mass-rename.py
  3) look at git diff (without --cached) to see what the damage is
"""


import os
import subprocess
import sys


BASE_DIR = os.path.abspath(os.path.dirname(__file__))


def main():
  popen = subprocess.Popen('git diff --cached --raw -M',
                           shell=True, stdout=subprocess.PIPE)
  out, _ = popen.communicate()
  if popen.returncode != 0:
    return 1
  for line in out.splitlines():
    parts = line.split('\t')
    if len(parts) != 3:
      print 'Skipping: %s -- not a rename?' % parts
      continue
    attrs, fro, to = parts
    if attrs.split()[4].startswith('R'):
      subprocess.check_call([
        sys.executable,
        os.path.join(BASE_DIR, 'move_source_file.py'),
        '--already_moved',
        '--no_error_for_non_source_file',
        fro, to])
    else:
      print 'Skipping: %s -- not a rename?' % fro
  return 0


if __name__ == '__main__':
  sys.exit(main())
