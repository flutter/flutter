#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generate java source files from protobuf files.

This is a helper file for the genproto_java action in protoc_java.gypi.

It performs the following steps:
1. Deletes all old sources (ensures deleted classes are not part of new jars).
2. Creates source directory.
3. Generates Java files using protoc (output into either --java-out-dir or
   --srcjar).
4. Creates a new stamp file.
"""

import os
import optparse
import shutil
import subprocess
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), "android", "gyp"))
from util import build_utils

def main(argv):
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option("--protoc", help="Path to protoc binary.")
  parser.add_option("--proto-path", help="Path to proto directory.")
  parser.add_option("--java-out-dir",
      help="Path to output directory for java files.")
  parser.add_option("--srcjar", help="Path to output srcjar.")
  parser.add_option("--stamp", help="File to touch on success.")
  options, args = parser.parse_args(argv)

  build_utils.CheckOptions(options, parser, ['protoc', 'proto_path'])
  if not options.java_out_dir and not options.srcjar:
    print 'One of --java-out-dir or --srcjar must be specified.'
    return 1

  with build_utils.TempDir() as temp_dir:
    # Specify arguments to the generator.
    generator_args = ['optional_field_style=reftypes',
                      'store_unknown_fields=true']
    out_arg = '--javanano_out=' + ','.join(generator_args) + ':' + temp_dir
    # Generate Java files using protoc.
    build_utils.CheckOutput(
        [options.protoc, '--proto_path', options.proto_path, out_arg]
        + args)

    if options.java_out_dir:
      build_utils.DeleteDirectory(options.java_out_dir)
      shutil.copytree(temp_dir, options.java_out_dir)
    else:
      build_utils.ZipDir(options.srcjar, temp_dir)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        args + [options.protoc] + build_utils.GetPythonDependencies())

  if options.stamp:
    build_utils.Touch(options.stamp)

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
