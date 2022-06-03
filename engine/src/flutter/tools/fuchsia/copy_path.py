#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Copies paths, creates if they do not exist.
"""

import argparse
import errno
import json
import os
import platform
import shutil
import subprocess
import sys


def EnsureParentExists(path):
  dir_name, _ = os.path.split(path)
  if not os.path.exists(dir_name):
    os.makedirs(dir_name)


def SameStat(s1, s2):
  return s1.st_ino == s2.st_ino and s1.st_dev == s2.st_dev


def SameFile(f1, f2):
  if not os.path.exists(f2):
    return False
  s1 = os.stat(f1)
  s2 = os.stat(f2)
  return SameStat(s1, s2)


def CopyPath(src, dst):
  try:
    EnsureParentExists(dst)
    shutil.copytree(src, dst)
  except OSError as exc:
    if exc.errno == errno.ENOTDIR:
      if not SameFile(src, dst):
        shutil.copyfile(src, dst)
    else:
      raise


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--file-list', dest='file_list', action='store', required=True
  )

  args = parser.parse_args()

  files = open(args.file_list, 'r')
  files_to_copy = files.read().split()
  num_files = len(files_to_copy) // 2

  for i in range(num_files):
    CopyPath(files_to_copy[i], files_to_copy[num_files + i])

  return 0


if __name__ == '__main__':
  sys.exit(main())
