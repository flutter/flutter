#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Usage: deps_parser.py --deps <DEPS file> --output <lockfile>
#
# This script parses the DEPS file, extracts the fully qualified dependencies
# and writes the to a file. This file will be later used to validate the dependencies
# are pinned to a hash.

import argparse
import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))

CHROMIUM_README_FILE = 'third_party/accessibility/README.md'
CHROMIUM_README_COMMIT_LINE = 4  # The fifth line will always contain the commit hash.
CHROMIUM = 'https://chromium.googlesource.com/chromium/src'


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
    # Inject default values for env variables.
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
  filtered_osv_deps = []
  for _, dep in deps.items():
    # We currently do not support packages or cipd which are represented
    # as dictionaries.
    if not isinstance(dep, str):
      continue

    dep_split = dep.rsplit('@', 1)
    filtered_osv_deps.append({
        'package': {'name': dep_split[0], 'commit': dep_split[1]}
    })

  osv_result = {
      'packageSource': {'path': deps_file, 'type': 'lockfile'},
      'packages': filtered_osv_deps
  }
  return osv_result


def parse_readme():
  """
  Opens the Flutter Accessibility Library README and uses the commit hash
  found in the README to check for viulnerabilities.
  The commit hash in this README will always be in the same format
  """
  file_path = os.path.join(CHECKOUT_ROOT, CHROMIUM_README_FILE)
  with open(file_path) as file:
    # Read the content of the file opened.
    content = file.readlines()
    commit_line = content[CHROMIUM_README_COMMIT_LINE]
    commit = re.search(r'(?<=\[).*(?=\])', commit_line)

    osv_result = {
        'packageSource': {'path': file_path, 'type': 'lockfile'},
        'packages': [{'package': {'name': CHROMIUM, 'commit': commit.group()}}]
    }

    return osv_result


def write_manifest(deps, manifest_file):
  output = {'results': deps}
  print(json.dumps(output, indent=2))
  with open(manifest_file, 'w') as manifest:
    json.dump(output, manifest, indent=2)


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to extract DEPS into osv-scanner lockfile compatible format.'
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
      help='Output lockfile.',
      default=os.path.join(CHECKOUT_ROOT, 'osv-lockfile.json')
  )

  return parser.parse_args(args)


def main(argv):
  args = parse_args(argv)
  deps_deps = parse_deps_file(args.deps)
  readme_deps = parse_readme()
  write_manifest([deps_deps, readme_deps], args.output)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
