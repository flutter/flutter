#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs semi-automated update testing on a non-rooted device.

This script will help verify that app data is preserved during an update.
To use this script first run it with the create_app_data option.

./update_verification.py create_app_data --old-apk <path> --app-data <path>

The script will then install the old apk, prompt you to create some app data
(bookmarks, etc.), and then save the app data in the path you gave it.

Next, once you have some app data saved, run this script with the test_update
option.

./update_verification.py test_update --old-apk <path> --new-apk <path>
--app-data <path>

This will install the old apk, load the saved app data, install the new apk,
and ask the user to verify that all of the app data was preserved.
"""

import argparse
import logging
import os
import sys
import time

from pylib import constants
from pylib.device import device_errors
from pylib.device import device_utils
from pylib.utils import apk_helper
from pylib.utils import run_tests_helper

def CreateAppData(device, old_apk, app_data, package_name):
  device.Install(old_apk)
  raw_input('Set the application state. Once ready, press enter and '
            'select "Backup my data" on the device.')
  device.adb.Backup(app_data, packages=[package_name])
  logging.critical('Application data saved to %s' % app_data)

def TestUpdate(device, old_apk, new_apk, app_data, package_name):
  device.Install(old_apk)
  device.adb.Restore(app_data)
  # Restore command is not synchronous
  raw_input('Select "Restore my data" on the device. Then press enter to '
            'continue.')
  device_path = device.GetApplicationPaths(package_name)
  if not device_path:
    raise Exception('Expected package %s to already be installed. '
                    'Package name might have changed!' % package_name)

  logging.info('Verifying that %s can be overinstalled.', new_apk)
  device.adb.Install(new_apk, reinstall=True)
  logging.critical('Successfully updated to the new apk. Please verify that '
                   'the application data is preserved.')

def main():
  parser = argparse.ArgumentParser(
      description="Script to do semi-automated upgrade testing.")
  parser.add_argument('-v', '--verbose', action='count',
                      help='Print verbose log information.')
  command_parsers = parser.add_subparsers(dest='command')

  subparser = command_parsers.add_parser('create_app_data')
  subparser.add_argument('--old-apk', required=True,
                         help='Path to apk to update from.')
  subparser.add_argument('--app-data', required=True,
                         help='Path to where the app data backup should be '
                           'saved to.')
  subparser.add_argument('--package-name',
                         help='Chrome apk package name.')

  subparser = command_parsers.add_parser('test_update')
  subparser.add_argument('--old-apk', required=True,
                         help='Path to apk to update from.')
  subparser.add_argument('--new-apk', required=True,
                         help='Path to apk to update to.')
  subparser.add_argument('--app-data', required=True,
                         help='Path to where the app data backup is saved.')
  subparser.add_argument('--package-name',
                         help='Chrome apk package name.')

  args = parser.parse_args()
  run_tests_helper.SetLogLevel(args.verbose)

  devices = device_utils.DeviceUtils.HealthyDevices()
  if not devices:
    raise device_errors.NoDevicesError()
  device = devices[0]
  logging.info('Using device %s for testing.' % str(device))

  package_name = (args.package_name if args.package_name
                  else apk_helper.GetPackageName(args.old_apk))
  if args.command == 'create_app_data':
    CreateAppData(device, args.old_apk, args.app_data, package_name)
  elif args.command == 'test_update':
    TestUpdate(
        device, args.old_apk, args.new_apk, args.app_data, package_name)
  else:
    raise Exception('Unknown test command: %s' % args.command)

if __name__ == '__main__':
  sys.exit(main())
