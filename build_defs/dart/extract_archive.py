#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Extracts a pub package archive (a gzipped tar) into a directory (pub.bzl).

Bazel's own extractor rejects an archive with bytes after the gzip stream
("Garbage after a valid .gz stream"), and some archives on pub.dev have them
(flutter_gallery_assets 1.0.2 ends in 4 KiB of zero padding); pub, GNU tar
and Python's tarfile read the stream and ignore what follows, as this does.
"""

import os
import sys
import tarfile

# A package's own Bazel files would make packages of its directories and
# hide their files from the repository's glob; the repository rule writes
# the one BUILD file the package gets.
_BAZEL_FILES = frozenset(['BUILD', 'BUILD.bazel', 'WORKSPACE', 'WORKSPACE.bazel', 'MODULE.bazel'])


def main():
  if len(sys.argv) != 3:
    sys.exit('usage: extract_archive.py <archive.tar.gz> <directory>')
  archive, directory = sys.argv[1:]
  with tarfile.open(archive, 'r:gz') as tar:
    # The data filter (3.11.4+) refuses members that would land outside the
    # directory and drops ownership and special bits, as pub's extraction does.
    if hasattr(tarfile, 'data_filter'):
      tar.extractall(directory, filter='data')
    else:
      tar.extractall(directory)
  for root, _, files in os.walk(directory):
    for name in files:
      if name in _BAZEL_FILES:
        os.remove(os.path.join(root, name))


if __name__ == '__main__':
  main()
