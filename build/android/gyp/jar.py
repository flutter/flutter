#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import fnmatch
import optparse
import os
import sys

from util import build_utils
from util import md5_check


def Jar(class_files, classes_dir, jar_path, manifest_file=None):
  jar_path = os.path.abspath(jar_path)

  # The paths of the files in the jar will be the same as they are passed in to
  # the command. Because of this, the command should be run in
  # options.classes_dir so the .class file paths in the jar are correct.
  jar_cwd = classes_dir
  class_files_rel = [os.path.relpath(f, jar_cwd) for f in class_files]
  jar_cmd = ['jar', 'cf0', jar_path]
  if manifest_file:
    jar_cmd[1] += 'm'
    jar_cmd.append(os.path.abspath(manifest_file))
  jar_cmd.extend(class_files_rel)

  with build_utils.TempDir() as temp_dir:
    empty_file = os.path.join(temp_dir, '.empty')
    build_utils.Touch(empty_file)
    jar_cmd.append(os.path.relpath(empty_file, jar_cwd))
    record_path = '%s.md5.stamp' % jar_path
    md5_check.CallAndRecordIfStale(
        lambda: build_utils.CheckOutput(jar_cmd, cwd=jar_cwd),
        record_path=record_path,
        input_paths=class_files,
        input_strings=jar_cmd,
        force=not os.path.exists(jar_path),
        )

    build_utils.Touch(jar_path, fail_if_missing=True)


def JarDirectory(classes_dir, excluded_classes, jar_path, manifest_file=None):
  class_files = build_utils.FindInDirectory(classes_dir, '*.class')
  for exclude in excluded_classes:
    class_files = filter(
        lambda f: not fnmatch.fnmatch(f, exclude), class_files)

  Jar(class_files, classes_dir, jar_path, manifest_file=manifest_file)


def main():
  parser = optparse.OptionParser()
  parser.add_option('--classes-dir', help='Directory containing .class files.')
  parser.add_option('--jar-path', help='Jar output path.')
  parser.add_option('--excluded-classes',
      help='List of .class file patterns to exclude from the jar.')
  parser.add_option('--stamp', help='Path to touch on success.')

  options, _ = parser.parse_args()

  if options.excluded_classes:
    excluded_classes = build_utils.ParseGypList(options.excluded_classes)
  else:
    excluded_classes = []
  JarDirectory(options.classes_dir,
               excluded_classes,
               options.jar_path)

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main())

