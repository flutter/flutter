#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Lays a framework bundle out and runs sky/tools/create_xcframework.py over it (framework.bzl's xcframework).

`xcrun xcodebuild -create-xcframework -framework <bundle>` wants the bundle
as a directory on disk, with its files and its symlinks (`Versions/Current
-> A`, the top-level links). Under Bazel the bundle is what its copies and
link actions place in the build directory, each an input of this action --
in a sandbox a link into the execution root, not the file -- so the bundle
is assembled here first, in a scratch directory: each `--entry
<file>=<path under the bundle>` is copied by content, or, for a symlink
output (a relative target, where the sandbox's own input links are
absolute), made again as the link it is. Then create_xcframework.py runs
with `--frameworks <scratch bundle>... --name <name> --location <location>`,
and writes `<location>/<name>.xcframework`, the declared directory.

Usage: xcframework.py [@params] --script <create_xcframework.py> --name <name>
         --location <dir> --framework <bundle name> [--entry <file>=<path>]...
         [--framework <bundle name> [--entry ...]...]...

The arguments are read in order: each --framework opens a bundle, and the
--entry arguments after it are that bundle's, until the next --framework.
"""

import os
import runpy
import shutil
import sys
import tempfile


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
  script = name = location = None
  bundles = []  # (bundle name, [entries])
  i = 0
  while i < len(args):
    option, value = args[i], args[i + 1]
    if option == '--script':
      script = value
    elif option == '--name':
      name = value
    elif option == '--location':
      location = value
    elif option == '--framework':
      bundles.append((value, []))
    elif option == '--entry':
      if not bundles:
        sys.exit('xcframework.py: --entry before any --framework')
      bundles[-1][1].append(value)
    else:
      sys.exit('xcframework.py: unknown option %s' % option)
    i += 2
  if not (script and name and location and bundles):
    sys.exit('xcframework.py: --script, --name, --location and a --framework are required')

  with tempfile.TemporaryDirectory() as scratch:
    frameworks = []
    for bundle, entries in bundles:
      root = os.path.join(scratch, bundle)
      os.makedirs(root)
      for entry in entries:
        source, path = entry.split('=', 1)
        destination = os.path.join(root, path)
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        if os.path.islink(source) and not os.path.isabs(os.readlink(source)):
          os.symlink(os.readlink(source), destination)
          continue
        shutil.copyfile(source, destination)
        shutil.copymode(source, destination)
      frameworks.append(root)
    sys.argv = [script, '--frameworks', *frameworks, '--name', name, '--location', location]
    runpy.run_path(script, run_name='__main__')


if __name__ == '__main__':
  main(sys.argv)
