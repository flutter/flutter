#!/usr/bin/python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import errno
import subprocess
import sys

PLUTIL = [
  '/usr/bin/env',
  'xcrun',
  'plutil'
]


def ProcessInfoPlist(args):
  output_plist_file = os.path.abspath(os.path.join(args.output, 'Info.plist'))
  return subprocess.check_call( PLUTIL + [
    '-convert',
    'binary1',
    '-o',
    output_plist_file,
    '--',
    args.input,
  ])


def PerformCodeSigning(args):
  return subprocess.check_call([
    '/usr/bin/env',
    'xcrun',
    'codesign',
    '--entitlements',
    args.entitlements_path,
    '--sign',
    args.identity,
    '-f',
    args.application_path,
  ])


def MakeDirectories(path):
  try:
    os.makedirs(path)
  except OSError as exc:
    if exc.errno == errno.EEXIST and os.path.isdir(path):
      return 0
    else:
      return -1

  return 0


def GenerateProjectStructure(args):
  application_path = os.path.join( args.dir, args.name + ".app" )
  return MakeDirectories( application_path )


def Main():
  parser = argparse.ArgumentParser(description='A script that aids in '
                                   'the creation of an iOS application')

  subparsers = parser.add_subparsers()

  # Plist Parser

  plist_parser = subparsers.add_parser('plist',
                                       help='Process the Info.plist')
  plist_parser.set_defaults(func=ProcessInfoPlist)
  
  plist_parser.add_argument('-i', dest='input', help='The input plist path')
  plist_parser.add_argument('-o', dest='output', help='The output plist dir')

  # Directory Structure Parser

  dir_struct_parser = subparsers.add_parser('structure',
                      help='Creates the directory of an iOS application')

  dir_struct_parser.set_defaults(func=GenerateProjectStructure)

  dir_struct_parser.add_argument('-d', dest='dir', help='Out directory')
  dir_struct_parser.add_argument('-n', dest='name', help='App name')

  # Code Signing

  code_signing_parser = subparsers.add_parser('codesign',
                        help='Code sign the specified application')

  code_signing_parser.set_defaults(func=PerformCodeSigning)

  code_signing_parser.add_argument('-p', dest='application_path', required=True,
                                   help='The application path')
  code_signing_parser.add_argument('-i', dest='identity', required=True,
                                   help='The code signing identity to use')
  code_signing_parser.add_argument('-e', dest='entitlements_path',
                                   required=True,
                                   help='The path to the entitlements .xcent')

  # Engage!

  args = parser.parse_args()
  
  return args.func(args)


if __name__ == '__main__':
  sys.exit(Main())
