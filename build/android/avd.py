#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Launches Android Virtual Devices with a set configuration for testing Chrome.

The script will launch a specified number of Android Virtual Devices (AVD's).
"""


import install_emulator_deps
import logging
import optparse
import os
import re
import sys

from pylib import cmd_helper
from pylib import constants
from pylib.utils import emulator


def main(argv):
  # ANDROID_SDK_ROOT needs to be set to the location of the SDK used to launch
  # the emulator to find the system images upon launch.
  emulator_sdk = os.path.join(constants.EMULATOR_SDK_ROOT, 'sdk')
  os.environ['ANDROID_SDK_ROOT'] = emulator_sdk

  opt_parser = optparse.OptionParser(description='AVD script.')
  opt_parser.add_option('--name', help='Optinaly, name of existing AVD to '
                        'launch. If not specified, new AVD\'s will be created')
  opt_parser.add_option('-n', '--num', dest='emulator_count',
                        help='Number of emulators to launch (default is 1).',
                        type='int', default='1')
  opt_parser.add_option('--abi', default='x86',
                        help='Platform of emulators to launch (x86 default).')
  opt_parser.add_option('--api-level', dest='api_level',
                        help='API level for the image, e.g. 19 for Android 4.4',
                        type='int', default=constants.ANDROID_SDK_VERSION)

  options, _ = opt_parser.parse_args(argv[1:])

  logging.basicConfig(level=logging.INFO,
                      format='# %(asctime)-15s: %(message)s')
  logging.root.setLevel(logging.INFO)

  # Check if KVM is enabled for x86 AVD's and check for x86 system images.
  # TODO(andrewhayden) Since we can fix all of these with install_emulator_deps
  # why don't we just run it?
  if options.abi == 'x86':
    if not install_emulator_deps.CheckKVM():
      logging.critical('ERROR: KVM must be enabled in BIOS, and installed. '
                       'Enable KVM in BIOS and run install_emulator_deps.py')
      return 1
    elif not install_emulator_deps.CheckX86Image(options.api_level):
      logging.critical('ERROR: System image for x86 AVD not installed. Run '
                       'install_emulator_deps.py')
      return 1

  if not install_emulator_deps.CheckSDK():
    logging.critical('ERROR: Emulator SDK not installed. Run '
                     'install_emulator_deps.py.')
    return 1

  # If AVD is specified, check that the SDK has the required target. If not,
  # check that the SDK has the desired target for the temporary AVD's.
  api_level = options.api_level
  if options.name:
    android = os.path.join(constants.EMULATOR_SDK_ROOT, 'sdk', 'tools',
                           'android')
    avds_output = cmd_helper.GetCmdOutput([android, 'list', 'avd'])
    names = re.findall(r'Name: (\w+)', avds_output)
    api_levels = re.findall(r'API level (\d+)', avds_output)
    try:
      avd_index = names.index(options.name)
    except ValueError:
      logging.critical('ERROR: Specified AVD %s does not exist.' % options.name)
      return 1
    api_level = int(api_levels[avd_index])

  if not install_emulator_deps.CheckSDKPlatform(api_level):
    logging.critical('ERROR: Emulator SDK missing required target for API %d. '
                     'Run install_emulator_deps.py.')
    return 1

  if options.name:
    emulator.LaunchEmulator(options.name, options.abi)
  else:
    emulator.LaunchTempEmulators(options.emulator_count, options.abi,
                                 options.api_level, True)



if __name__ == '__main__':
  sys.exit(main(sys.argv))
