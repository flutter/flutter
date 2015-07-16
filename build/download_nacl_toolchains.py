#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Shim to run nacl toolchain download script only if there is a nacl dir."""

import os
import shutil
import sys


def Main(args):
  # Exit early if disable_nacl=1.
  if 'disable_nacl=1' in os.environ.get('GYP_DEFINES', ''):
    return 0
  script_dir = os.path.dirname(os.path.abspath(__file__))
  src_dir = os.path.dirname(script_dir)
  nacl_dir = os.path.join(src_dir, 'native_client')
  nacl_build_dir = os.path.join(nacl_dir, 'build')
  package_version_dir = os.path.join(nacl_build_dir, 'package_version')
  package_version = os.path.join(package_version_dir, 'package_version.py')
  if not os.path.exists(package_version):
    print "Can't find '%s'" % package_version
    print 'Presumably you are intentionally building without NativeClient.'
    print 'Skipping NativeClient toolchain download.'
    sys.exit(0)
  sys.path.insert(0, package_version_dir)
  import package_version

  # BUG:
  # We remove this --optional-pnacl argument, and instead replace it with
  # --no-pnacl for most cases.  However, if the bot name is an sdk
  # bot then we will go ahead and download it.  This prevents increasing the
  # gclient sync time for developers, or standard Chrome bots.
  if '--optional-pnacl' in args:
    args.remove('--optional-pnacl')
    use_pnacl = False
    buildbot_name = os.environ.get('BUILDBOT_BUILDERNAME', '')
    if 'pnacl' in buildbot_name and 'sdk' in buildbot_name:
      use_pnacl = True
    if use_pnacl:
      print '\n*** DOWNLOADING PNACL TOOLCHAIN ***\n'
    else:
      args = ['--exclude', 'pnacl_newlib'] + args

  # Only download the ARM gcc toolchain if we are building for ARM
  # TODO(olonho): we need to invent more reliable way to get build
  # configuration info, to know if we're building for ARM.
  if 'target_arch=arm' not in os.environ.get('GYP_DEFINES', ''):
      args = ['--exclude', 'nacl_arm_newlib'] + args

  package_version.main(args)

  return 0


if __name__ == '__main__':
  sys.exit(Main(sys.argv[1:]))
