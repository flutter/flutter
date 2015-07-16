#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import sys

CURRENT_PATH = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, os.path.join(CURRENT_PATH, "pylib"))
import gs

PREBUILT_FILE_PATH = os.path.join(CURRENT_PATH, "prebuilt", "frameworks")

FILES_TO_DOWNLOAD = [
  "apptest.dartzip",
]

def download(tools_directory, version_file):
  stamp_path = os.path.join(PREBUILT_FILE_PATH, "VERSION")

  version_path = os.path.join(CURRENT_PATH, version_file)
  with open(version_path) as version_file:
    version = version_file.read().strip()

  try:
    with open(stamp_path) as stamp_file:
      current_version = stamp_file.read().strip()
      if current_version == version:
        return 0  # Already have the right version.
  except IOError:
    pass  # If the stamp file does not exist we need to download new binaries.

  for file_name in FILES_TO_DOWNLOAD:
    download_file(file_name, version, tools_directory)

  with open(stamp_path, 'w') as stamp_file:
    stamp_file.write(version)
  return 0


def download_file(basename, version, tools_directory):
  find_depot_tools_path = os.path.join(CURRENT_PATH, tools_directory)
  sys.path.insert(0, find_depot_tools_path)
  # pylint: disable=F0401
  import find_depot_tools
  depot_tools_path = find_depot_tools.add_depot_tools_to_path()

  gs_path = "gs://mojo/file/" + version + "/" + basename

  output_file = os.path.join(PREBUILT_FILE_PATH, basename)
  gs.download_from_public_bucket(gs_path, output_file,
                                 depot_tools_path)


def main():
  parser = argparse.ArgumentParser(description="Downloads bundled frameworks "
      "binaries from google storage.")
  parser.add_argument("--tools-directory",
                      dest="tools_directory",
                      metavar="<tools-directory>",
                      type=str,
                      required=True,
                      help="Path to the directory containing "
                           "find_depot_tools.py, specified as a relative path "
                           "from the location of this file.")
  parser.add_argument("--version-file",
                      dest="version_file",
                      metavar="<version-file>",
                      type=str,
                      default="../VERSION",
                      help="Path to the file containing the version of the "
                           "shell to be fetched, specified as a relative path "
                           "from the location of this file (default: "
                           "%(default)s).")
  args = parser.parse_args()
  return download(args.tools_directory, args.version_file)


if __name__ == "__main__":
  sys.exit(main())
