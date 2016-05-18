#!/usr/bin/env python
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''Creates the iOS native service SDK that developers can use the create
native services that can be dynamically loaded.'''

import errno
import os
import shutil
import sys
import argparse
import subprocess


def mkdir_p(path):
  try:
    os.makedirs(path)
  except OSError as exc:
    if exc.errno == errno.EEXIST and os.path.isdir(path):
      pass
    else:
      raise


def main():
  parser = argparse.ArgumentParser(description=__doc__)

  parser.add_argument('--simulator-out-dir',
                      dest='simulator_out_dir',
                      required=True,
                      help='The out directory for the simulator assets.')
  parser.add_argument('--device-out-dir',
                      dest='device_out_dir',
                      required=True,
                      help='The out directory for the device assets.')
  parser.add_argument('--dest',
                      dest='dest',
                      required=True,
                      help='The directory in which to create the SDK.')
  parser.add_argument('--harness',
                      dest='harness',
                      required=True,
                      help='The SDK harness to use.')
  parser.add_argument('headers',
                  metavar='H',
                  nargs='+',
                  help='A list of header directories to copy over to the SDK.')

  args = parser.parse_args()

  simulator_out_dir = os.path.abspath(args.simulator_out_dir)
  device_out_dir = os.path.abspath(args.device_out_dir)

  archive_path = 'obj/sky/services/dynamic/libFlutterService.a'

  simulator_archive = os.path.join(simulator_out_dir, archive_path)
  device_archive = os.path.join(device_out_dir, archive_path)

  sdk_dir = os.path.join(os.path.abspath(args.dest), 'ServiceSDK')

  if os.path.isdir(sdk_dir):
    shutil.rmtree(sdk_dir)

  shutil.copytree(os.path.abspath(args.harness), os.path.join(sdk_dir))

  library_path = os.path.join(sdk_dir, 'Library')
  header_path = os.path.join(sdk_dir, 'Headers')

  mkdir_p(library_path)
  mkdir_p(header_path)

  subprocess.call([
    'lipo',
    simulator_archive,
    device_archive,
    '-create',
    '-output',
    os.path.join(library_path, 'libFlutterService.a'),
  ])

  src_root = os.path.join(os.path.dirname(__file__), '../../')
  for headers_dir in args.headers:
    for root, _, files in os.walk(headers_dir):
      for file in files:
        if file.endswith(".h"):
          source = os.path.abspath(os.path.join(root, file))
          relative = os.path.relpath(source, src_root)
          destination = os.path.abspath(os.path.join(header_path, relative))
          destination_dir = os.path.dirname(destination)
          mkdir_p(destination_dir)
          shutil.copyfile(source, destination)

  return 0


if __name__ == '__main__':
  sys.exit(main())
