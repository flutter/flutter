#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This script runs "pub get" on all directories within the tree that have
pubspec.yaml files.

See https://www.dartlang.org/tools/pub/get-started.html for information about
the pub tool."""

import argparse
import os
import subprocess
import sys

def pub_get(dart_sdk_path, target_directory, upgrade):
  cmd = [
    os.path.join(dart_sdk_path, "bin/pub")
  ]
  if upgrade:
    cmd.extend(["upgrade"])
  else:
    cmd.extend(["get"])

  # Cache the downloaded pubs inside the repo to avoid the chance of multiple
  # simultaneous builds in different repos stomping on each other.
  env = os.environ.copy()
  env["PUB_CACHE"] = os.path.join(os.getcwd(), "dart-pub-cache")
  try:
      subprocess.check_output(cmd, shell=False,
                              stderr=subprocess.STDOUT,
                              cwd=target_directory,
                              env=env)
  except subprocess.CalledProcessError as e:
    print('Error running pub get in %s' % target_directory)
    print(e.output)
    raise e



def main(repository_root, dart_sdk_path, dirs_to_ignore, upgrade):
  os.chdir(repository_root)

  # Relativize dart_sdk_path to repository_root.
  dart_sdk_path_from_root = os.path.join(repository_root,
      os.path.relpath(dart_sdk_path, repository_root))

  cmd = ["git", "ls-files", "*/pubspec.yaml"]
  pubspec_yaml_files = subprocess.check_output(cmd,
                                               shell=False,
                                               stderr=subprocess.STDOUT)

  for f in pubspec_yaml_files.split():
    ignore = reduce(lambda x, y: x or f.startswith(y), dirs_to_ignore, False)
    if ignore:
      continue
    pub_get(dart_sdk_path_from_root, os.path.dirname(f), upgrade)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(
      description="Run 'pub get' on all directories with checked-in "
                  "pubspec.yaml files")
  parser.add_argument("--repository-root",
                      metavar="<repository-root>",
                      type=str,
                      required=True,
                      help="Path to the root of the Git repository, "
                           "specified as a relative path from this directory.")
  parser.add_argument("--dart-sdk-directory",
                      metavar="<dart-sdk-directory>",
                      type=str,
                      required=True,
                      help="Path to the directory containing the Dart SDK, "
                           "specified as a relative path from this directory.")
  parser.add_argument("--dirs-to-ignore",
                      metavar="<dir>",
                      nargs="+",
                      default=[],
                      type=str,
                      help="Optional list of directories to ignore, specified "
                           "relative to the root of the repo. 'pub get' will "
                           "not be run for any subdirectories of these "
                           "directories.")
  parser.add_argument("--upgrade",
                      action="store_true",
                      default=False,
                      help="Upgrade pub package dependencies")
  args = parser.parse_args()
  _current_path = os.path.dirname(os.path.realpath(__file__))
  _repository_root = os.path.join(_current_path, args.repository_root)
  _dart_sdk_path = os.path.join(_current_path, args.dart_sdk_directory)
  sys.exit(
      main(_repository_root, _dart_sdk_path, args.dirs_to_ignore, args.upgrade))
