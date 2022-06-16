#!/usr/bin/env python3
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
  parser.add_argument('--fidlgen-bin', dest='fidlgen_bin', action='store', required=False)

  parser.add_argument('--sdk-base', dest='sdk_base', action='store', required=True)
  parser.add_argument('--root', dest='root', action='store', required=True)
  parser.add_argument('--json', dest='json', action='store', required=True)
  parser.add_argument('--fidlgen-output-root', dest='fidlgen_output_root', action='store', required=False)
  parser.add_argument('--output-c-tables', dest='output_c_tables', action='store', required=True)
  parser.add_argument('--target-api-level', dest='target_api_level', action='store', required=False)

  args = parser.parse_args()

  assert os.path.exists(args.fidlc_bin)
  # --fidlgen-bin and --fidlgen-output-root should be passed in together.
  assert os.path.exists(args.fidlgen_bin or '') == bool(args.fidlgen_output_root)

  fidl_files_by_name = GetFIDLFilesByLibraryName(args.sdk_base, args.root)

  fidlc_command = [
    args.fidlc_bin,
    '--tables',
    args.output_c_tables,
    '--json',
    args.json
  ]

  if args.target_api_level:
    fidlc_command += [
      '--available',
      'fuchsia:{api_level}'.format(api_level=args.target_api_level),
    ]

  # Create an iterator that works on both python3 and python2
  try:
    fidl_files_by_name_iter = list(fidl_files_by_name.items())
  except AttributeError:
    fidl_files_by_name_iter = iter(fidl_files_by_name.items())

  for _, fidl_files in fidl_files_by_name_iter:
    fidlc_command.append('--files')
    for fidl_file in fidl_files:
      fidl_abspath = os.path.abspath('%s/%s' % (args.sdk_base, fidl_file))
      fidlc_command.append(fidl_abspath)

  subprocess.check_call(fidlc_command)

  if args.fidlgen_output_root:
    assert os.path.exists(args.json)
    fidlgen_command = [
      args.fidlgen_bin,
      '-json',
      args.json,
      '-root',
      args.fidlgen_output_root
    ]

    subprocess.check_call(fidlgen_command)

  return 0

if __name__ == '__main__':
  sys.exit(main())
