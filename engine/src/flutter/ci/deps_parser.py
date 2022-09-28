#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: deps_parser.py --deps <DEPS file> --output <flattened deps>
#
# This script parses the DEPS file, extracts the fully qualified dependencies
# and writes the to a file. This file will be later used to validate the dependencies
# are pinned to a hash.

import argparse
import os
import sys

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))


# Used in parsing the DEPS file.
class VarImpl:
  _env_vars = {
      'host_cpu': 'x64',
      'host_os': 'linux',
  }

  def __init__(self, local_scope):
    self._local_scope = local_scope

  def lookup(self, var_name):
    """Implements the Var syntax."""
    if var_name in self._local_scope.get('vars', {}):
      return self._local_scope['vars'][var_name]
    # Inject default values for env variables
    if var_name in self._env_vars:
      return self._env_vars[var_name]
    raise Exception('Var is not defined: %s' % var_name)


def parse_deps_file(deps_file):
  local_scope = {}
  var = VarImpl(local_scope)
  global_scope = {
      'Var': var.lookup,
      'deps_os': {},
  }
  # Read the content.
  with open(deps_file, 'r') as file:
    deps_content = file.read()

  # Eval the content.
  exec(deps_content, global_scope, local_scope)

  # Extract the deps and filter.
  deps = local_scope.get('deps', {})
  filtered_deps = []
  for val in deps.values():
    # We currently do not support packages or cipd which are represented
    # as dictionaries.
    if isinstance(val, str):
      filtered_deps.append(val)

  return filtered_deps


def write_manifest(deps, manifest_file):
  print('\n'.join(sorted(deps)))
  with open(manifest_file, 'w') as manifest:
    manifest.write('\n'.join(sorted(deps)))


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to flatten a gclient DEPS file.'
  )

  parser.add_argument(
      '--deps',
      '-d',
      type=str,
      help='Input DEPS file.',
      default=os.path.join(CHECKOUT_ROOT, 'DEPS')
  )
  parser.add_argument(
      '--output',
      '-o',
      type=str,
      help='Output flattened deps file.',
      default=os.path.join(CHECKOUT_ROOT, 'deps_flatten.txt')
  )

  return parser.parse_args(args)


def main(argv):
  args = parse_args(argv)
  deps = parse_deps_file(args.deps)
  write_manifest(deps, args.output)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
