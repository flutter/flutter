#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Copies the Info.plist and adds extra fields to it like the git hash of the
engine.

Precondition: $CWD/../../flutter is the path to the flutter engine repo.

usage: copy_info_plist.py --source <src_path> --destination <dest_path>
                          --bitcode --minversion=<deployment_target>
"""

import argparse
import os
import subprocess

import git_revision


def get_clang_version(bitcode):
  clang_executable = str(
      os.path.join(
          '..', '..', 'buildtools', 'mac-x64', 'clang', 'bin', 'clang++'
      )
  )
  if bitcode:
    clang_executable = 'clang++'
  version = subprocess.check_output([clang_executable, '--version'])
  return version.splitlines()[0]


def main():

  parser = argparse.ArgumentParser(
      description='Copies the Info.plist and adds extra fields to it like the '
      'git hash of the engine'
  )

  parser.add_argument(
      '--source',
      help='Path to Info.plist source template',
      type=str,
      required=True
  )
  parser.add_argument(
      '--destination',
      help='Path to destination Info.plist',
      type=str,
      required=True
  )
  parser.add_argument(
      '--bitcode', help='Built with bitcode', action='store_true'
  )
  parser.add_argument(
      '--minversion', help='Minimum device OS version like "9.0"', type=str
  )

  args = parser.parse_args()

  text = open(args.source).read()
  engine_path = os.path.join(os.getcwd(), '..', '..', 'flutter')
  revision = git_revision.get_repository_version(engine_path)
  bitcode = args.bitcode is not None
  clang_version = get_clang_version(bitcode)
  text = text.format(
      revision=revision,
      clang_version=clang_version,
      min_version=args.minversion
  )

  with open(args.destination, 'w') as outfile:
    outfile.write(text)


if __name__ == '__main__':
  main()
