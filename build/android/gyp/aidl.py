#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Invokes Android's aidl
"""

import optparse
import os
import sys

from util import build_utils


def main(argv):
  option_parser = optparse.OptionParser()
  build_utils.AddDepfileOption(option_parser)
  option_parser.add_option('--aidl-path', help='Path to the aidl binary.')
  option_parser.add_option('--imports', help='Files to import.')
  option_parser.add_option('--includes',
                           help='Directories to add as import search paths.')
  option_parser.add_option('--srcjar', help='Path for srcjar output.')
  options, args = option_parser.parse_args(argv[1:])

  with build_utils.TempDir() as temp_dir:
    for f in args:
      classname = os.path.splitext(os.path.basename(f))[0]
      output = os.path.join(temp_dir, classname + '.java')
      aidl_cmd = [options.aidl_path]
      aidl_cmd += [
        '-p' + s for s in build_utils.ParseGypList(options.imports)
      ]
      if options.includes is not None:
        aidl_cmd += [
          '-I' + s for s in build_utils.ParseGypList(options.includes)
        ]
      aidl_cmd += [
        f,
        output
      ]
      build_utils.CheckOutput(aidl_cmd)

    build_utils.ZipDir(options.srcjar, temp_dir)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())


if __name__ == '__main__':
  sys.exit(main(sys.argv))
