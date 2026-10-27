#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Runs build/zip.py over the files a Bazel zip_bundle's entries name (zip_bundle.bzl).

zip.py stores a symlink as a symlink entry (a macOS framework's), and every
input of a sandboxed action is a symlink, where GN hands the script its build
directory's real files. Each `-i` source is resolved to the file it names
before zip.py sees it -- a directory (the javadoc tree, a tree artifact
whose files the sandbox links one by one) to a copy with its files
resolved, since zip.py keeps a directory's symlinks as symlinks; everything
else is zip.py's own command line. A source that is a symlink output of the
build (a framework bundle's `Versions/Current -> A`, framework.bzl), which
Bazel hands over as the symlink it is, with its relative target, stays one:
that is the entry GN's archive has. The sandbox's own links are absolute.

Usage: zip_bundle.py <zip.py> -o <output> -i <source> <destination>...
"""

import os
import runpy
import shutil
import sys
import tempfile


def main(argv):
  script = argv[1]
  args = argv[2:]
  with tempfile.TemporaryDirectory() as resolved_trees:
    for i, arg in enumerate(args):
      if arg == '-i' and i + 1 < len(args):
        source = args[i + 1]
        if os.path.islink(source) and not os.path.isabs(os.readlink(source)):
          continue
        source = os.path.realpath(source)
        if os.path.isdir(source):
          copy = os.path.join(resolved_trees, str(i))
          shutil.copytree(source, copy, symlinks=False)
          source = copy
        args[i + 1] = source
    sys.argv = [script] + args
    runpy.run_path(script, run_name='__main__')


if __name__ == '__main__':
  main(sys.argv)
