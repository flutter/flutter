#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Insert a version string into a library as a section '.chromium.version'.
"""

import optparse
import os
import sys
import tempfile

from util import build_utils

def InsertChromiumVersion(android_objcopy,
                          library_path,
                          version_string):
  # Remove existing .chromium.version section from .so
  objcopy_command = [android_objcopy,
                     '--remove-section=.chromium.version',
                     library_path]
  build_utils.CheckOutput(objcopy_command)

  # Add a .chromium.version section.
  with tempfile.NamedTemporaryFile() as stream:
    stream.write(version_string)
    stream.flush()
    objcopy_command = [android_objcopy,
                       '--add-section', '.chromium.version=%s' % stream.name,
                       library_path]
    build_utils.CheckOutput(objcopy_command)

def main(args):
  args = build_utils.ExpandFileArgs(args)
  parser = optparse.OptionParser()

  parser.add_option('--android-objcopy',
      help='Path to the toolchain\'s objcopy binary')
  parser.add_option('--stripped-libraries-dir',
      help='Directory of native libraries')
  parser.add_option('--libraries',
      help='List of libraries')
  parser.add_option('--version-string',
      help='Version string to be inserted')
  parser.add_option('--stamp', help='Path to touch on success')

  options, _ = parser.parse_args(args)
  libraries = build_utils.ParseGypList(options.libraries)

  for library in libraries:
    library_path = os.path.join(options.stripped_libraries_dir, library)

    InsertChromiumVersion(options.android_objcopy,
                          library_path,
                          options.version_string)

  if options.stamp:
    build_utils.Touch(options.stamp)

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
