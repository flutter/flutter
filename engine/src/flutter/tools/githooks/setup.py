#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''
Sets up githooks.
'''

import os
import subprocess
import sys
from shutil import which  # Natively supported since python 3.3

SRC_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    )
)
FLUTTER_DIR = os.path.join(SRC_ROOT, 'flutter')


def Main(argv):
  githooks = os.path.join(FLUTTER_DIR, 'tools', 'githooks')
  git_candidates = ['git', 'git.sh', 'git.bat']
  git = next(filter(which, git_candidates), None)
  if git is None:
    candidates = "', '".join(git_candidates)
    raise IOError(f"Looks like GIT is not on the path. Tried '{candidates}'")
  result = subprocess.run([
      git,
      'config',
      'core.hooksPath',
      githooks,
  ],
                          cwd=FLUTTER_DIR)
  return result.returncode


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
