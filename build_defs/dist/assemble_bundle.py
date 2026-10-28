#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Lays a framework bundle out as a directory, from what the build places under it (framework.bzl).

A bundle under Bazel is what its copies and link actions place in the
build directory; a compile or link that wants the bundle as a directory on
disk (`-F<dir>` with `#import <FlutterMacOS/FlutterMacOS.h>`, GN's
umbrella-import check) gets it assembled here into a declared directory:
each `--entry <file>=<path under the bundle>` is copied by content, or, for
a symlink output (a relative target, where the sandbox's own input links
are absolute), made again as the link it is.

Usage: assemble_bundle.py [@params] --out <bundle directory> [--entry <file>=<path>]...
"""

import os
import shutil
import sys


def _expanded(argv):
  """argv with Bazel's parameter files (`@file`, one argument per line) read in."""
  out = []
  for arg in argv:
    if arg.startswith('@'):
      with open(arg[1:]) as params:
        out.extend(line.rstrip('\n') for line in params)
    else:
      out.append(arg)
  return out


def main(argv):
  args = _expanded(argv[1:])
  out = None
  entries = []
  i = 0
  while i < len(args):
    option, value = args[i], args[i + 1]
    if option == '--out':
      out = value
    elif option == '--entry':
      entries.append(value)
    else:
      sys.exit('assemble_bundle.py: unknown option %s' % option)
    i += 2
  if not out or not entries:
    sys.exit('assemble_bundle.py: --out and an --entry are required')
  os.makedirs(out, exist_ok=True)
  for entry in entries:
    source, path = entry.split('=', 1)
    destination = os.path.join(out, path)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    if os.path.islink(source) and not os.path.isabs(os.readlink(source)):
      os.symlink(os.readlink(source), destination)
      continue
    shutil.copyfile(source, destination)
    shutil.copymode(source, destination)


if __name__ == '__main__':
  main(sys.argv)
