#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Generate C/C++ headers and source files from the set of FIDL files specified
in the meta.json manifest.
"""


import argparse
import collections
import json
import os
import subprocess
import sys

def GetFIDLFilesRecursive(libraries, sdk_base, path):
  with open(path) as json_file:
    parsed = json.load(json_file)
    result = []
    deps =  parsed['deps']
    for dep in deps:
      dep_meta_json = os.path.abspath('%s/fidl/%s/meta.json' % (sdk_base, dep))
      GetFIDLFilesRecursive(libraries, sdk_base, dep_meta_json)
    libraries[parsed['name']] = result + parsed['sources']

def GetFIDLFilesByLibraryName(sdk_base, root):
  libraries = collections.OrderedDict()
  GetFIDLFilesRecursive(libraries, sdk_base, root)
  return libraries

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--fidlc-bin', dest='fidlc_bin', action='store', required=True)
  parser.add_argument('--fidlgen-bin', dest='fidlgen_bin', action='store', required=True)
  
  parser.add_argument('--sdk-base', dest='sdk_base', action='store', required=True)
  parser.add_argument('--root', dest='root', action='store', required=True)
  parser.add_argument('--json', dest='json', action='store', required=True)
  parser.add_argument('--include-base', dest='include_base', action='store', required=True)
  parser.add_argument('--output-base-cc', dest='output_base_cc', action='store', required=True)
  parser.add_argument('--output-c-header', dest='output_header_c', action='store', required=True)
  parser.add_argument('--output-c-tables', dest='output_c_tables', action='store', required=True)

  args = parser.parse_args()

  assert os.path.exists(args.fidlc_bin)
  assert os.path.exists(args.fidlgen_bin)

  fidl_files_by_name = GetFIDLFilesByLibraryName(args.sdk_base, args.root)

  fidlc_command = [
    args.fidlc_bin,
    '--c-header',
    args.output_header_c,
    '--tables',
    args.output_c_tables,
    '--json',
    args.json
  ]

  for _, fidl_files in fidl_files_by_name.iteritems():
    fidlc_command.append('--files')
    for fidl_file in fidl_files:
      fidl_abspath = os.path.abspath('%s/%s' % (args.sdk_base, fidl_file))
      fidlc_command.append(fidl_abspath)

  subprocess.check_call(fidlc_command);

  assert os.path.exists(args.json)

  fidlgen_command = [
    args.fidlgen_bin,
    '-generators',
    'cpp',
    '-include-base',
    args.include_base,
    '-json',
    args.json,
    '-output-base',
    args.output_base_cc
  ]

  subprocess.check_call(fidlgen_command)

  return 0

if __name__ == '__main__':
  sys.exit(main())
