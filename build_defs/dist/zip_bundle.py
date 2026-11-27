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

zip.py stores each file with the mode it has (ZipFile.write), which in GN's
build directory is the file's own and in Bazel's is not: an action's output
is 0555 whatever it holds, a file fetched from CIPD 0600 or 0700. Each
regular file is stored with the mode it ships with instead (modes.py: 0755
for a program, 0644 for the rest), which is the mode GN's archive has.

Usage: zip_bundle.py <zip.py> -o <output> -i <source> <destination>...
"""

import os
import runpy
import shutil
import stat
import sys
import tempfile
import zipfile

# modes.py, beside this script.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import modes  # pylint: disable=wrong-import-position


def _store_shipped_modes():
  """Has zipfile record a regular file's shipped mode in place of its own.

  ZipFile.write, which zip.py calls for every file, builds the entry with
  ZipInfo.from_file: the file's st_mode in the upper half of external_attr.
  """
  from_file = zipfile.ZipInfo.from_file.__func__

  def shipped(cls, filename, arcname=None, **kwargs):
    info = from_file(cls, filename, arcname, **kwargs)
    if not info.is_dir():
      info.external_attr = (stat.S_IFREG | modes.shipped_mode(filename)) << 16
    return info

  zipfile.ZipInfo.from_file = classmethod(shipped)


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
    _store_shipped_modes()
    sys.argv = [script] + args
    runpy.run_path(script, run_name='__main__')


if __name__ == '__main__':
  main(sys.argv)
