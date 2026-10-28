#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Assembles a directory from files and directories (local_engine.bzl's `assemble`).

Each `--file <source>=<path>` is copied to <path> under the output directory;
each `--directory <source>=<path>` has its contents copied under <path>
(`.` for the output directory itself). Copies, not links: Bazel's
output-tree files are read-only and a tree artifact is one unit. A file
that is a symlink output of the build (a framework bundle's
`Versions/Current -> A`, framework.bzl: a relative target, where the
sandbox's own input links are absolute) is made again as the link it is --
also when the sandbox's absolute link leads to it (a link inside a
directory output, an xcframework's framework: the sandbox stages the
directory's entries one by one, each as a link to the output tree's).
"""

import argparse
import os
import shutil


def build_link(source):
  """The relative target of the build's own link at `source`, if it is one; else None."""
  if not os.path.islink(source):
    return None
  target = os.readlink(source)
  if not os.path.isabs(target):
    return target
  # The sandbox's link to the output tree's file: the build's own link, if
  # the file there is one.
  if os.path.islink(target) and not os.path.isabs(os.readlink(target)):
    return os.readlink(target)
  return None


def copy_file(source, destination):
  link = build_link(source)
  if link is not None:
    if os.path.lexists(destination):
      os.remove(destination)
    os.symlink(link, destination)
    return
  shutil.copyfile(source, destination)
  shutil.copymode(source, destination)


def copy_tree(source, destination):
  os.makedirs(destination, exist_ok=True)
  for name in sorted(os.listdir(source)):
    entry = os.path.join(source, name)
    target = os.path.join(destination, name)
    if build_link(entry) is None and os.path.isdir(entry):
      copy_tree(entry, target)
    else:
      copy_file(entry, target)


def main():
  # Bazel passes the arguments in a file, one per line (@<file>).
  parser = argparse.ArgumentParser(
      description=__doc__.split('\n', maxsplit=1)[0], fromfile_prefix_chars='@'
  )
  parser.add_argument('--output', required=True)
  parser.add_argument('--file', action='append', default=[], help='<source>=<path>')
  parser.add_argument('--directory', action='append', default=[], help='<source>=<path>')
  options = parser.parse_args()

  os.makedirs(options.output, exist_ok=True)
  for entry in options.directory:
    source, path = entry.split('=', 1)
    destination = os.path.normpath(os.path.join(options.output, path))
    copy_tree(source, destination)
  for entry in options.file:
    source, path = entry.split('=', 1)
    destination = os.path.join(options.output, path)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    copy_file(source, destination)


if __name__ == '__main__':
  main()
