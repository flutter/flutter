#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Generate a Fuchsia repo capable of serving Fuchsia archives over the
network.
"""
import argparse
import collections
import json
import os
import subprocess
import sys


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument('--pm-bin', dest='pm_bin', action='store', required=True)
  parser.add_argument(
      '--repo-dir', dest='repo_dir', action='store', required=True
  )
  parser.add_argument(
      '--archive', dest='archives', action='append', required=True
  )

  args = parser.parse_args()

  assert os.path.exists(args.pm_bin)

  if not os.path.exists(args.repo_dir):
    pm_newrepo_command = [args.pm_bin, 'newrepo', '-repo', args.repo_dir]
    subprocess.check_call(pm_newrepo_command)

  pm_publish_command = [
      args.pm_bin,
      'publish',
      '-C',  # Remove all previous registrations.
      '-a',  # Publish archives from an archive (mode).
      '-repo',
      args.repo_dir
  ]

  for archive in args.archives:
    pm_publish_command.append('-f')
    pm_publish_command.append(archive)

  subprocess.check_call(pm_publish_command)

  return 0


if __name__ == '__main__':
  sys.exit(main())
