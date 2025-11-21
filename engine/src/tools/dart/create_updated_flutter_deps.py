#!/usr/bin/env python3
#
# Copyright 2017 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: tools/dart/create_updated_flutter_deps.py [-d dart/DEPS] [-f flutter/DEPS]
#
# This script parses existing flutter DEPS file, identifies all 'dart_' prefixed
# dependencies, looks up revision from dart DEPS file, updates those dependencies
# and rewrites flutter DEPS file.

import argparse
import os
import sys

DART_SCRIPT_DIR = os.path.dirname(sys.argv[0])
OLD_DART_DEPS = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../third_party/dart/DEPS'))
DART_DEPS = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../flutter/third_party/dart/DEPS'))
FLUTTER_DEPS = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../../../DEPS'))

# Path to Dart SDK checkout within Flutter repo.
DART_SDK_ROOT = 'engine/src/flutter/third_party/dart'

class VarImpl(object):
  def __init__(self, local_scope):
    self._local_scope = local_scope

  def Lookup(self, var_name):
    """Implements the Var syntax."""
    if var_name in self._local_scope.get("vars", {}):
      return self._local_scope["vars"][var_name]
    if var_name == 'host_os':
      return 'linux' # assume some default value
    if var_name == 'host_cpu':
      return 'x64' # assume some default value
    raise Exception("Var is not defined: %s" % var_name)


def ParseDepsFile(deps_file):
  local_scope = {}
  var = VarImpl(local_scope)
  global_scope = {
    'Var': var.Lookup,
    'deps_os': {},
  }
  # Read the content.
  with open(deps_file, 'r') as fp:
    deps_content = fp.read()

  # Eval the content.
  exec(deps_content, global_scope, local_scope)

  return (local_scope.get('vars', {}), local_scope.get('deps', {}))

def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to generate updated dart dependencies for flutter DEPS.')
  parser.add_argument('--dart_deps', '-d',
      type=str,
      help='Dart DEPS file.',
      default=DART_DEPS)
  parser.add_argument('--flutter_deps', '-f',
      type=str,
      help='Flutter DEPS file.',
      default=FLUTTER_DEPS)
  return parser.parse_args(args)

def PrettifySourcePathForDEPS(flutter_vars, dep_path, source):
  """Prepare source for writing into Flutter DEPS file.

  If source is not a string then it is expected to be a dictionary defining
  a CIPD dependency. In this case it is written as is - but sorted to
  guarantee stability of the output.

  Otherwise source is a path to a repo plus version (hash or tag):

      {repo_host}/{repo_path}@{version}

  We want to convert this into one of the following:

      Var(repo_host_var) + 'repo_path' + '@' + Var(version_var)
      Var(repo_host_var) + 'repo_path@version'
      'source'

  Where repo_host_var is one of '*_git' variables and version_var is one
  of 'dart_{dep_name}_tag' or 'dart_{dep_name}_rev' variables.
  """

  # If this a CIPD dependency then keep it as-is but sort its contents
  # to ensure stable ordering.
  if not isinstance(source, str):
    return dict(sorted(source.items()))

  # Decompose source into {repo_host}/{repo_path}@{version}
  repo_host_var = None
  version_var = None
  repo_path_with_version = source
  for var_name, var_value in flutter_vars.items():
    if var_name.endswith("_git") and source.startswith(var_value):
      repo_host_var = var_name
      repo_path_with_version = source[len(var_value):]
      break

  if repo_path_with_version.find('@') == -1:
    raise ValueError(f'{dep_path} source is unversioned')

  repo_path, version = repo_path_with_version.split('@', 1)

  # Figure out the name of the dependency from its path to compute
  # corresponding version_var.
  #
  # Normally, the last component of the dep_path is the name of the dependency.
  # However some dependencies are placed in a subdirectory named "src"
  # within a directory named after the dependency.
  dep_name = os.path.basename(dep_path)
  if dep_name == 'src':
    dep_name = os.path.basename(os.path.dirname(dep_path))
  for var_name in [f'dart_{dep_name}_tag', f'dart_{dep_name}_rev']:
    if var_name in flutter_vars:
      version_var = var_name
      break

  # Format result from available individual pieces.
  result = []
  if repo_host_var is not None:
    result += [f"Var('{repo_host_var}')"]
  if version_var is not None:
    result += [f"'{repo_path}'", "'@'", f"Var('{version_var}')"]
  else:
    result += [f"'{repo_path_with_version}'"]
  return " + ".join(result)

def ComputeDartDeps(flutter_vars, flutter_deps, dart_deps):
  """Compute sources for deps nested under DART_SDK_ROOT in Flutter DEPS.

  These dependencies originate from Dart SDK, so their version are
  computed by looking them up in Dart DEPS using appropriately
  relocated paths, e.g. '{DART_SDK_ROOT}/third_party/foo' is located at
  'sdk/third_party/foo' in Dart DEPS.

  Source paths are expressed in terms of 'xyz_git' and 'dart_xyz_tag' or
  'dart_xyz_rev' variables if possible.

  If corresponding path is not found in Dart DEPS the dependency is considered
  no longer needed and is removed from Flutter DEPS.

  Returns: dictionary of dependencies
  """
  new_dart_deps = {}

  # Trailing / to avoid matching Dart SDK dependency itself.
  dart_sdk_root_dir = DART_SDK_ROOT + '/'

  # Find all dependencies which are nested inside Dart SDK and check
  # if Dart SDK still needs them. If Dart DEPS still mentions them
  # take updated version from Dart DEPS.
  for (dep_path, dep_source) in sorted(flutter_deps.items()):
    if dep_path.startswith(dart_sdk_root_dir):
      # Dart dependencies are given relative to root directory called `sdk/`.
      dart_dep_path = f'sdk/{dep_path[len(dart_sdk_root_dir):]}'
      if dart_dep_path in dart_deps:
        # Still used, add it to the result.
        new_dart_deps[dep_path] = PrettifySourcePathForDEPS(flutter_vars, dep_path, dart_deps[dart_dep_path])

  return new_dart_deps

def Main(argv):
  args = ParseArgs(argv)
  if args.dart_deps == DART_DEPS and not os.path.isfile(DART_DEPS):
    args.dart_deps = OLD_DART_DEPS
  (dart_vars, dart_deps) = ParseDepsFile(args.dart_deps)
  (flutter_vars, flutter_deps) = ParseDepsFile(args.flutter_deps)

  updated_vars = {}

  # Collect updated dependencies
  for (k,v) in sorted(flutter_vars.items()):
    if k not in ('dart_revision', 'dart_git') and k.startswith('dart_'):
      dart_key = k[len('dart_'):]
      if dart_key in dart_vars:
        updated_vars[k] = dart_vars[dart_key].lstrip('@')

  new_dart_deps = ComputeDartDeps(flutter_vars, flutter_deps, dart_deps)

  # Write updated DEPS file to a side
  updatedfilename = args.flutter_deps + ".new"
  updatedfile = open(updatedfilename, "w")
  file = open(args.flutter_deps)
  lines = file.readlines()
  i = 0
  while i < len(lines):
    updatedfile.write(lines[i])
    if lines[i].startswith("  'dart_revision':"):
      i = i + 2
      updatedfile.writelines([
        '\n',
        '  # WARNING: DO NOT EDIT MANUALLY\n',
        '  # The lines between blank lines above and below are generated by a script. See create_updated_flutter_deps.py\n'])
      while i < len(lines) and len(lines[i].strip()) > 0:
        i = i + 1
      for (k, v) in sorted(updated_vars.items()):
        updatedfile.write("  '%s': '%s',\n" % (k, v))
      updatedfile.write('\n')

    elif lines[i].startswith("  # WARNING: Unused Dart dependencies"):
      updatedfile.write('\n')
      i = i + 1
      while i < len(lines) and not lines[i].startswith("  # WARNING: end of dart dependencies"):
        i = i + 1

      for dep_path, dep_source in new_dart_deps.items():
        updatedfile.write(f"  '{dep_path}':\n   {dep_source},\n\n")

      updatedfile.write(lines[i])
    i = i + 1

  # Rename updated DEPS file into a new DEPS file
  os.remove(args.flutter_deps)
  os.rename(updatedfilename, args.flutter_deps)

  return 0

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
