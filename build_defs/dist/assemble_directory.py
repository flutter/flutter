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


def relink_frameworks(root):
  """Makes a versioned framework bundle's directory links again where a copy stands in for one.

  A directory output's own links to directories (an xcframework's
  FlutterMacOS.framework: `Versions/Current -> A`, `Headers ->
  Versions/Current/Headers`, ...) reach a later action's sandbox as
  directories -- Bazel lists a tree artifact's files through them -- so the
  copy above has the version's contents twice over, a bundle codesign and
  Xcode may refuse. The recipe meets the same after LUCI's CAS dereferences a
  framework's links and makes them again (sky_utils._regenerate_symlinks);
  this does the same for what was a link: Versions/Current becomes the link
  to the one version, and each top-level copy of a version's item the link
  to it under Versions/Current. A flat bundle (an iOS framework) has no
  Versions and is left alone.
  """
  for directory, subdirectories, _ in os.walk(root):
    if not directory.endswith('.framework'):
      continue
    versions = os.path.join(directory, 'Versions')
    if not os.path.isdir(versions) or os.path.islink(versions):
      continue
    current = os.path.join(versions, 'Current')
    if os.path.islink(current):
      version = os.readlink(current)
    else:
      names = [n for n in os.listdir(versions) if n != 'Current']
      if len(names) != 1:
        continue
      version = names[0]
      if os.path.lexists(current):
        shutil.rmtree(current)
      os.symlink(version, current)
    for item in os.listdir(os.path.join(versions, version)):
      top = os.path.join(directory, item)
      if not os.path.lexists(top) or os.path.islink(top):
        continue
      if os.path.isdir(top):
        shutil.rmtree(top)
      else:
        os.remove(top)
      os.symlink(os.path.join('Versions', 'Current', item), top)
    # The bundle's own subdirectories are done; the version's are not walked again.
    subdirectories[:] = []


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
    relink_frameworks(destination)
  for entry in options.file:
    source, path = entry.split('=', 1)
    destination = os.path.join(options.output, path)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    copy_file(source, destination)


if __name__ == '__main__':
  main()
