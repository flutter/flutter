# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os


def ContainsLicenseBlock(source_file):
  # This check is somewhat easier than in the engine because all sources need to
  # have the same license.
  py_license = '''# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.'''
  c_license = py_license.replace("#", "//")

  # Make sure we don't read the entire file into memory.
  read_size = (max(len(py_license), len(c_license)))

  for license in [c_license, py_license]:
    with open(source_file) as source:
      if source.read(read_size).startswith(license):
        return True

  return False


def IsSourceFile(path):
  known_extensions = [
    ".cc",
    ".cpp",
    ".c",
    ".h",
    ".hpp",
    ".py",
    ".sh",
    ".gn",
    ".gni",
    ".glsl",
    ".sl.h",
    ".vert",
    ".frag",
    ".tesc",
    ".tese",
    ".yaml",
    ".dart",
  ]
  for extension in known_extensions:
    if os.path.basename(path).endswith(extension):
      return True
  return False;


# Checks that all source files have the same license preamble.
def Main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--source-root",
                    type=str, required=True,
                    help="The source root.")
  args = parser.parse_args()

  assert(os.path.exists(args.source_root))

  source_files = set()

  for root, dirs, files in os.walk(os.path.abspath(args.source_root)):
    for file in files:
      file_path = os.path.join(root, file)
      if IsSourceFile(file_path):
        source_files.add(file_path)

  for source_file in source_files:
    if not ContainsLicenseBlock(source_file):
      raise Exception("Could not find valid license block in source ", source_file)

if __name__ == '__main__':
  Main()
