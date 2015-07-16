#!/usr/bin/env python
#
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Command line tool for forwarding ports from a device to the host.

Allows an Android device to connect to services running on the host machine,
i.e., "adb forward" in reverse. Requires |host_forwarder| and |device_forwarder|
to be built.
"""

import logging
import optparse
import sys
import time

from pylib import constants
from pylib import forwarder
from pylib.device import adb_wrapper
from pylib.device import device_errors
from pylib.device import device_utils
from pylib.utils import run_tests_helper


def main(argv):
  parser = optparse.OptionParser(usage='Usage: %prog [options] device_port '
                                 'host_port [device_port_2 host_port_2] ...',
                                 description=__doc__)
  parser.add_option('-v',
                    '--verbose',
                    dest='verbose_count',
                    default=0,
                    action='count',
                    help='Verbose level (multiple times for more)')
  parser.add_option('--device',
                    help='Serial number of device we should use.')
  parser.add_option('--debug', action='store_const', const='Debug',
                    dest='build_type', default='Release',
                    help='Use Debug build of host tools instead of Release.')

  options, args = parser.parse_args(argv)
  run_tests_helper.SetLogLevel(options.verbose_count)

  if len(args) < 2 or not len(args) % 2:
    parser.error('Need even number of port pairs')
    sys.exit(1)

  try:
    port_pairs = map(int, args[1:])
    port_pairs = zip(port_pairs[::2], port_pairs[1::2])
  except ValueError:
    parser.error('Bad port number')
    sys.exit(1)

  devices = device_utils.DeviceUtils.HealthyDevices()

  if options.device:
    device = next((d for d in devices if d == options.device), None)
    if not device:
      raise device_errors.DeviceUnreachableError(options.device)
  elif devices:
    device = devices[0]
    logging.info('No device specified. Defaulting to %s', devices[0])
  else:
    raise device_errors.NoDevicesError()

  constants.SetBuildType(options.build_type)
  try:
    forwarder.Forwarder.Map(port_pairs, device)
    while True:
      time.sleep(60)
  except KeyboardInterrupt:
    sys.exit(0)
  finally:
    forwarder.Forwarder.UnmapAllDevicePorts(device)

if __name__ == '__main__':
  main(sys.argv)
