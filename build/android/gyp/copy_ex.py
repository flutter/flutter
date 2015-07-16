#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Copies files to a directory."""

import optparse
import os
import shutil
import sys

from util import build_utils


def _get_all_files(base):
  """Returns a list of all the files in |base|. Each entry is relative to the
  last path entry of |base|."""
  result = []
  dirname = os.path.dirname(base)
  for root, _, files in os.walk(base):
    result.extend([os.path.join(root[len(dirname):], f) for f in files])
  return result


def main(args):
  args = build_utils.ExpandFileArgs(args)

  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--dest', help='Directory to copy files to.')
  parser.add_option('--files', action='append',
                    help='List of files to copy.')
  parser.add_option('--clear', action='store_true',
                    help='If set, the destination directory will be deleted '
                    'before copying files to it. This is highly recommended to '
                    'ensure that no stale files are left in the directory.')
  parser.add_option('--stamp', help='Path to touch on success.')

  options, _ = parser.parse_args(args)

  if options.clear:
    build_utils.DeleteDirectory(options.dest)
    build_utils.MakeDirectory(options.dest)

  files = []
  for file_arg in options.files:
    files += build_utils.ParseGypList(file_arg)

  deps = []

  for f in files:
    if os.path.isdir(f):
      if not options.clear:
        print ('To avoid stale files you must use --clear when copying '
               'directories')
        sys.exit(-1)
      shutil.copytree(f, os.path.join(options.dest, os.path.basename(f)))
      deps.extend(_get_all_files(f))
    else:
      shutil.copy(f, options.dest)
      deps.append(f)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        deps + build_utils.GetPythonDependencies())

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))

