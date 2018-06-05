#!/usr/bin/env python
# Copyright 2017 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: tools/dart/create_updated_flutter_deps.py [-d dart/DEPS] [-f flutter/DEPS]
#
# This script parses existing flutter DEPS file, identifies all 'dart_' prefixed
# dependencies, looks up revision from dart DEPS file and prints a list of updated
# revision to the console so it can be copy'n'pasted into flutter DEPS file.

import argparse
import os
import sys

DART_SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../third_party/dart'))
FLUTTER_ROOT = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../flutter'))

class VarImpl(object):
  def __init__(self, local_scope):
    self._local_scope = local_scope

  def Lookup(self, var_name):
    """Implements the Var syntax."""
    if var_name in self._local_scope.get("vars", {}):
      return self._local_scope["vars"][var_name]
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

  return local_scope.get('vars', {})

def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to generate updated dart dependencies for flutter DEPS.')
  parser.add_argument('--dart_deps', '-d',
      type=str,
      help='Dart DEPS file.',
      default=os.path.join(DART_ROOT, 'DEPS'))
  parser.add_argument('--flutter_deps', '-f',
      type=str,
      help='Flutter DEPS file.',
      default=os.path.join(FLUTTER_ROOT, 'DEPS'))
  return parser.parse_args(args)

def Main(argv):
  args = ParseArgs(argv)
  new_deps = ParseDepsFile(args.dart_deps)
  old_deps = ParseDepsFile(args.flutter_deps)
  for (k,v) in sorted(old_deps.iteritems()):
    if k not in ('dart_revision', 'dart_git') and k.startswith('dart_'):
      v = '???'
      dart_key = k[len('dart_'):]
      updated_revision = new_deps[dart_key].lstrip('@') if new_deps.has_key(dart_key) else v
      print "  '%s': '%s'," % (k, updated_revision)
  return 0

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
