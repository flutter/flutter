#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility script to install APKs from the command line quickly."""

import optparse
import os
import sys

from pylib import constants
from pylib.device import device_errors
from pylib.device import device_utils


def AddInstallAPKOption(option_parser):
  """Adds apk option used to install the APK to the OptionParser."""
  option_parser.add_option('--apk',
                           help=('DEPRECATED The name of the apk containing the'
                                 ' application (with the .apk extension).'))
  option_parser.add_option('--apk_package',
                           help=('DEPRECATED The package name used by the apk '
                                 'containing the application.'))
  option_parser.add_option('--keep_data',
                           action='store_true',
                           default=False,
                           help=('Keep the package data when installing '
                                 'the application.'))
  option_parser.add_option('--debug', action='store_const', const='Debug',
                           dest='build_type',
                           default=os.environ.get('BUILDTYPE', 'Debug'),
                           help='If set, run test suites under out/Debug. '
                           'Default is env var BUILDTYPE or Debug')
  option_parser.add_option('--release', action='store_const', const='Release',
                           dest='build_type',
                           help='If set, run test suites under out/Release. '
                           'Default is env var BUILDTYPE or Debug.')
  option_parser.add_option('-d', '--device', dest='device',
                           help='Target device for apk to install on.')


def ValidateInstallAPKOption(option_parser, options, args):
  """Validates the apk option and potentially qualifies the path."""
  if not options.apk:
    if len(args) > 1:
      options.apk = args[1]
    else:
      option_parser.error('apk target not specified.')

  if not options.apk.endswith('.apk'):
    options.apk += '.apk'

  if not os.path.exists(options.apk):
    options.apk = os.path.join(constants.GetOutDirectory(), 'apks',
                               options.apk)


def main(argv):
  parser = optparse.OptionParser()
  parser.set_usage("usage: %prog [options] target")
  AddInstallAPKOption(parser)
  options, args = parser.parse_args(argv)

  if len(args) > 1 and options.apk:
    parser.error("Appending the apk as argument can't be used with --apk.")
  elif len(args) > 2:
    parser.error("Too many arguments.")

  constants.SetBuildType(options.build_type)
  ValidateInstallAPKOption(parser, options, args)

  devices = device_utils.DeviceUtils.HealthyDevices()

  if options.device:
    devices = [d for d in devices if d == options.device]
    if not devices:
      raise device_errors.DeviceUnreachableError(options.device)
  elif not devices:
    raise device_errors.NoDevicesError()

  device_utils.DeviceUtils.parallel(devices).Install(
      options.apk, reinstall=options.keep_data)


if __name__ == '__main__':
  sys.exit(main(sys.argv))

