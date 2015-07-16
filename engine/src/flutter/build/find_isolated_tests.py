#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Scans build output directory for .isolated files, calculates their SHA1
hashes, stores final list in JSON document and then removes *.isolated files
found (to ensure no stale *.isolated stay around on the next build).

Used to figure out what tests were build in isolated mode to trigger these
tests to run on swarming.

For more info see:
https://sites.google.com/a/chromium.org/dev/developers/testing/isolated-testing
"""

import glob
import hashlib
import json
import optparse
import os
import re
import sys


def hash_file(filepath):
  """Calculates the hash of a file without reading it all in memory at once."""
  digest = hashlib.sha1()
  with open(filepath, 'rb') as f:
    while True:
      chunk = f.read(1024*1024)
      if not chunk:
        break
      digest.update(chunk)
  return digest.hexdigest()


def main():
  parser = optparse.OptionParser(
      usage='%prog --build-dir <path> --output-json <path>',
      description=sys.modules[__name__].__doc__)
  parser.add_option(
      '--build-dir',
      help='Path to a directory to search for *.isolated files.')
  parser.add_option(
      '--output-json',
      help='File to dump JSON results into.')

  options, _ = parser.parse_args()
  if not options.build_dir:
    parser.error('--build-dir option is required')
  if not options.output_json:
    parser.error('--output-json option is required')

  result = {}

  # Get the file hash values and output the pair.
  pattern = os.path.join(options.build_dir, '*.isolated')
  for filepath in sorted(glob.glob(pattern)):
    test_name = os.path.splitext(os.path.basename(filepath))[0]
    if re.match(r'^.+?\.\d$', test_name):
      # It's a split .isolated file, e.g. foo.0.isolated. Ignore these.
      continue

    # TODO(csharp): Remove deletion once the isolate tracked dependencies are
    # inputs for the isolated files.
    sha1_hash = hash_file(filepath)
    os.remove(filepath)
    result[test_name] = sha1_hash

  with open(options.output_json, 'wb') as f:
    json.dump(result, f)

  return 0


if __name__ == '__main__':
  sys.exit(main())
