#!/usr/bin/python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import errno
import os
import re
import subprocess
import sys
import time

IOS_SIM_PATH = [
  '/Applications/iOS Simulator.app/Contents/MacOS/iOS Simulator'
]

SIMCTL_PATH = [
  '/usr/bin/env',
  'xcrun',
  'simctl',
]

PLIST_BUDDY_PATH = [
  '/usr/bin/env',
  'xcrun',
  'PlistBuddy',
]


def ApplicationIdentifier(path):
  identifier = subprocess.check_output( PLIST_BUDDY_PATH + [
    '-c',
    'Print CFBundleIdentifier',
    '%s/Info.plist' % path,
  ])

  return identifier.strip()

def IsDeviceBooted():
  devices = subprocess.check_output( SIMCTL_PATH + [ 'list', 'devices' ]).strip().split('\n')
  for device in devices:
    if re.search(r'\(Booted\)', device):
      return True
  return False

# Launch whatever simulator the user last used, rather than try to guess which of their simulators they might want to use
def Boot(args):
  if IsDeviceBooted():
    return

  # Use Popen here because launching the simulator from the command line in this manner doesn't return, so we can't check the result.
  if args.ios_sim_path:
    subprocess.Popen( args.ios_sim_path )
  else:
    subprocess.Popen( IOS_SIM_PATH )

  while not IsDeviceBooted():
    print('Waiting for iOS Simulator to boot...')
    time.sleep(0.5)

def Install(args):
  Boot(args)
  return subprocess.check_call( SIMCTL_PATH + [
    'install',
    'booted',
    args.path,
  ])


def InstallLaunchAndWait(args, wait):
  res = Install(args)

  if res != 0:
    return res

  identifier = ApplicationIdentifier(args.path)

  launch_args = [ 'launch' ]

  if wait:
    launch_args += [ '-w' ]

  launch_args += [
    'booted',
    identifier,
    '-target',
    args.target,
    '-server',
    args.server
  ]

  return subprocess.check_output( SIMCTL_PATH + launch_args ).strip()


def Launch(args):
  InstallLaunchAndWait(args, False)


def Debug(args):
  launch_res = InstallLaunchAndWait(args, True)
  launch_pid = re.search('.*: (\d+)', launch_res).group(1)
  return os.system(' '.join([
    '/usr/bin/env',
    'xcrun',
    'lldb',
    '-s',
    os.path.join(os.path.dirname(__file__), 'lldb_start_commands.txt'),
    '-p',
    launch_pid,
  ]))


def Main():
  parser = argparse.ArgumentParser(description='A script that launches an'
                                   ' application in the simulator and attaches'
                                   ' the debugger to it.')

  parser.add_argument('-p', dest='path', required=True,
                      help='Path to the simulator application.')

  parser.add_argument('-t', dest='target', required=False,
                      default='examples/demo_launcher/lib/main.dart',
                      help='Sky server-relative path to the Sky app to run.')

  parser.add_argument('-s', dest='server', required=False,
                      default='localhost:8080',
                      help='Sky server address.')

  parser.add_argument('--ios_sim_path', dest='ios_sim_path',
                      help='Path to your iOS Simulator executable. '
                      'Not normally required.')

  subparsers = parser.add_subparsers()

  launch_parser = subparsers.add_parser('launch', help='Launch')
  launch_parser.set_defaults(func=Launch)

  install_parser = subparsers.add_parser('install', help='Install')
  install_parser.set_defaults(func=Install)

  debug_parser = subparsers.add_parser('debug', help='Debug')
  debug_parser.set_defaults(func=Debug)

  args = parser.parse_args()

  return args.func(args)


if __name__ == '__main__':
  sys.exit(Main())
