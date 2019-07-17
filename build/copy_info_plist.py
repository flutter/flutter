#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Copies the Info.plist and adds extra fields to it like the git hash of the
engine.

Precondition: $CWD/../../flutter is the path to the flutter engine repo.

usage: copy_info_plist.py <src_path> <dest_path> --bitcode=<enable_bitcode>
"""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import subprocess

import sys
import git_revision
import os

def GetClangVersion(bitcode) :
  clang_executable = str(os.path.join("..", "..", "buildtools", "mac-x64", "clang", "bin", "clang++"))
  if bitcode:
    clang_executable = "clang++"
  version = subprocess.check_output([clang_executable, "--version"])
  return version.splitlines()[0]

def main():
  text = open(sys.argv[1]).read()
  engine_path = os.path.join(os.getcwd(), "..", "..", "flutter")
  revision = git_revision.GetRepositoryVersion(engine_path)
  clang_version = GetClangVersion(sys.argv[3] == "--bitcode=true")
  text = text.format(revision, clang_version)

  with open(sys.argv[2], "w") as outfile:
    outfile.write(text)

if __name__ == "__main__":
  main()
