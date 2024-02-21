# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os


def contains_license_block(source_file):
  # This check is somewhat easier than in the engine because all sources need to
  # have the same license.
  py_license = """# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file."""
  c_license = py_license.replace('#', '//')

  # Make sure we don't read the entire file into memory.
  read_size = (max(len(py_license), len(c_license)))

  for lic in [c_license, py_license]:
    with open(source_file) as source:
      if source.read(read_size).startswith(lic):
        return True

  return False


def is_source_file(path):
  known_extensions = [
      '.cc',
      '.cpp',
      '.c',
      '.h',
      '.hpp',
      '.py',
      '.sh',
      '.gn',
      '.gni',
      '.glsl',
      '.sl.h',
      '.vert',
      '.frag',
      '.tesc',
      '.tese',
      '.yaml',
      '.dart',
  ]
  for extension in known_extensions:
    if os.path.basename(path).endswith(extension):
      return True
  return False


# Checks that all source files have the same license preamble.
def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--source-root', type=str, required=True, help='The source root.')
  args = parser.parse_args()

  assert os.path.exists(args.source_root)

  source_files = set()

  for root, _, files in os.walk(os.path.abspath(args.source_root)):
    for file in files:
      file_path = os.path.join(root, file)
      if is_source_file(file_path):
        source_files.add(file_path)

  for source_file in source_files:
    if not contains_license_block(source_file):
      raise Exception('Could not find valid license block in source ', source_file)


if __name__ == '__main__':
  main()
