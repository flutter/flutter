#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
A simple wrapper for protoc.

- Adds includes in generated headers.
- Handles building with system protobuf as an option.
"""

import fnmatch
import optparse
import os.path
import shutil
import subprocess
import sys
import tempfile

PROTOC_INCLUDE_POINT = '// @@protoc_insertion_point(includes)\n'

def ModifyHeader(header_file, extra_header):
  """Adds |extra_header| to |header_file|. Returns 0 on success.

  |extra_header| is the name of the header file to include.
  |header_file| is a generated protobuf cpp header.
  """
  include_point_found = False
  header_contents = []
  with open(header_file) as f:
    for line in f:
      header_contents.append(line)
      if line == PROTOC_INCLUDE_POINT:
        extra_header_msg = '#include "%s"\n' % extra_header
        header_contents.append(extra_header_msg)
        include_point_found = True;
  if not include_point_found:
    return 1

  with open(header_file, 'wb') as f:
    f.write(''.join(header_contents))
  return 0

def ScanForBadFiles(scan_root):
  """Scan for bad file names, see http://crbug.com/386125 for details.
  Returns True if any filenames are bad. Outputs errors to stderr.

  |scan_root| is the path to the directory to be recursively scanned.
  """
  badname = False
  real_scan_root = os.path.realpath(scan_root)
  for dirpath, dirnames, filenames in os.walk(real_scan_root):
    matches = fnmatch.filter(filenames, '*-*.proto')
    if len(matches) > 0:
      if not badname:
        badname = True
        sys.stderr.write('proto files must not have hyphens in their names ('
                         'see http://crbug.com/386125 for more information):\n')
      for filename in matches:
        sys.stderr.write('  ' + os.path.join(real_scan_root,
                                             dirpath, filename) + '\n')
  return badname


def RewriteProtoFilesForSystemProtobuf(path):
  wrapper_dir = tempfile.mkdtemp()
  try:
    for filename in os.listdir(path):
      if not filename.endswith('.proto'):
        continue
      with open(os.path.join(path, filename), 'r') as src_file:
        with open(os.path.join(wrapper_dir, filename), 'w') as dst_file:
          for line in src_file:
            # Remove lines that break build with system protobuf.
            # We cannot optimize for lite runtime, because system lite runtime
            # does not have a Chromium-specific hack to retain unknown fields.
            # Similarly, it does not understand corresponding option to control
            # the usage of that hack.
            if 'LITE_RUNTIME' in line or 'retain_unknown_fields' in line:
              continue
            dst_file.write(line)

    return wrapper_dir
  except:
    shutil.rmtree(wrapper_dir)
    raise


def main(argv):
  parser = optparse.OptionParser()
  parser.add_option('--include', dest='extra_header',
                    help='The extra header to include. This must be specified '
                         'along with --protobuf.')
  parser.add_option('--protobuf', dest='generated_header',
                    help='The c++ protobuf header to add the extra header to. '
                         'This must be specified along with --include.')
  parser.add_option('--proto-in-dir',
                    help='The directory containing .proto files.')
  parser.add_option('--proto-in-file', help='Input file to compile.')
  parser.add_option('--use-system-protobuf', type=int, default=0,
                    help='Option to use system-installed protobuf '
                         'instead of bundled one.')
  (options, args) = parser.parse_args(sys.argv)
  if len(args) < 2:
    return 1

  if ScanForBadFiles(options.proto_in_dir):
    return 1

  proto_path = options.proto_in_dir
  if options.use_system_protobuf == 1:
    proto_path = RewriteProtoFilesForSystemProtobuf(proto_path)
  try:
    # Run what is hopefully protoc.
    protoc_args = args[1:]
    protoc_args += ['--proto_path=%s' % proto_path,
                    os.path.join(proto_path, options.proto_in_file)]
    ret = subprocess.call(protoc_args)
    if ret != 0:
      return ret
  finally:
    if options.use_system_protobuf == 1:
      # Remove temporary directory holding re-written files.
      shutil.rmtree(proto_path)

  # protoc succeeded, check to see if the generated cpp header needs editing.
  if not options.extra_header or not options.generated_header:
    return 0
  return ModifyHeader(options.generated_header, options.extra_header)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
