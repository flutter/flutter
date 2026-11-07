#!/usr/bin/env vpython3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import os
import subprocess
import sys

# This script queries malioc for the list of GPU cores it supports and the
# maximum OpenGL ES / Vulkan versions of each core, and writes the result to
# impeller/tools/malioc_cores.json in a form that can be consumed by GN (see
# impeller/tools/malioc.gni).
#
# The JSON file is checked in so that `gn gen` does not have to run malioc.
# Re-run this script whenever the malioc CIPD package is updated (see
# tools/cipd/malioc/README.md) and commit the result.

DEFAULT_OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'malioc_cores.json')


def parse_args(argv):
  parser = argparse.ArgumentParser(
      description='This script sanitizes GPU core info output from malioc',
  )
  parser.add_argument(
      '--malioc',
      '-m',
      type=str,
      help='The path to malioc.',
  )
  parser.add_argument(
      '--output',
      '-o',
      type=str,
      default=DEFAULT_OUTPUT,
      help='The output path. Defaults to %(default)s.',
  )
  return parser.parse_args(argv)


def validate_args(args):
  if not args.malioc or not os.path.isfile(args.malioc):
    print('The --malioc argument must refer to the malioc binary.')
    return False
  return True


def malioc_core_list(malioc):
  malioc_cores = subprocess.check_output(
      [malioc, '--list', '--format', 'json'],
      stderr=subprocess.STDOUT,
  )
  cores_json = json.loads(malioc_cores)
  cores = []
  for core in cores_json['cores']:
    cores.append(core['core'])
  return cores


def malioc_core_info(malioc, core):
  malioc_info = subprocess.check_output(
      [malioc, '--info', '--core', core, '--format', 'json'],
      stderr=subprocess.STDOUT,
  )
  info_json = json.loads(malioc_info)

  apis = info_json['apis']

  opengles_max_version = 0
  if 'opengles' in apis:
    opengles = apis['opengles']
    if opengles['max_version'] is not None:
      opengles_max_version = opengles['max_version']
  vulkan_max_version = 0
  if 'vulkan' in apis:
    vulkan = apis['vulkan']
    if vulkan['max_version'] is not None:
      vulkan_max_version = int(vulkan['max_version'] * 100)

  info = {
      'core': core,
      'opengles_max_version': opengles_max_version,
      'vulkan_max_version': vulkan_max_version,
  }
  return info


def main(argv):
  args = parse_args(argv[1:])
  if not validate_args(args):
    return 1

  infos = []
  for core in malioc_core_list(args.malioc):
    infos.append(malioc_core_info(args.malioc, core))

  with open(args.output, 'w') as file:
    json.dump(infos, file, sort_keys=True, indent=2)
    file.write('\n')

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
