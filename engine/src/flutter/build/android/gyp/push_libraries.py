#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Pushes native libraries to a device.

"""

import optparse
import os
import sys

BUILD_ANDROID_DIR = os.path.join(os.path.dirname(__file__), os.pardir)
sys.path.append(BUILD_ANDROID_DIR)

from pylib import constants

from util import build_device
from util import build_utils
from util import md5_check

def DoPush(options):
  libraries = build_utils.ParseGypList(options.libraries)

  device = build_device.GetBuildDeviceFromPath(
      options.build_device_configuration)
  if not device:
    return

  serial_number = device.GetSerialNumber()
  # A list so that it is modifiable in Push below.
  needs_directory = [True]
  for lib in libraries:
    device_path = os.path.join(options.device_dir, lib)
    host_path = os.path.join(options.libraries_dir, lib)

    def Push():
      if needs_directory:
        device.RunShellCommand('mkdir -p ' + options.device_dir)
        needs_directory[:] = [] # = False
      device.PushChangedFiles([(host_path, device_path)])

    record_path = '%s.%s.push.md5.stamp' % (host_path, serial_number)
    md5_check.CallAndRecordIfStale(
        Push,
        record_path=record_path,
        input_paths=[host_path],
        input_strings=[device_path])


def main(args):
  args = build_utils.ExpandFileArgs(args)
  parser = optparse.OptionParser()
  parser.add_option('--libraries-dir',
      help='Directory that contains stripped libraries.')
  parser.add_option('--device-dir',
      help='Device directory to push the libraries to.')
  parser.add_option('--libraries',
      help='List of native libraries.')
  parser.add_option('--stamp', help='Path to touch on success.')
  parser.add_option('--build-device-configuration',
      help='Path to build device configuration.')
  parser.add_option('--configuration-name',
      help='The build CONFIGURATION_NAME')
  options, _ = parser.parse_args(args)

  required_options = ['libraries', 'device_dir', 'libraries']
  build_utils.CheckOptions(options, parser, required=required_options)
  constants.SetBuildType(options.configuration_name)

  DoPush(options)

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
