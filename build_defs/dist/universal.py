#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Lays several builds out and runs one of the recipe's generator scripts over them (universal.bzl's apple_universal).

sky/tools/create_macos_framework.py, create_macos_gen_snapshots.py and
create_ios_framework.py read build directories (`--arm64-out-dir <dir>`:
<dir>/FlutterMacOS.framework, <dir>/universal/gen_snapshot_arm64, ...) and
write into `--dst`. Under Bazel each build's files are inputs of this
action -- in a sandbox links into the execution root -- so each build is
laid out first in a scratch directory from its `--entry <file>=<path>`
arguments (copied by content; a link of the build's own -- a framework
bundle's `Versions/Current -> A`, a relative target, where the sandbox's
input links are absolute and may lead to such a link -- made again as the
link it is), the script runs with its `--arg`s, `{build:<key>}` and `{dst}`
expanded to the scratch directories, and each `--output <path under
dst>=<declared output>` is copied out, a directory with its links.

Usage: universal.py [@params] --script <script> [--build <key> [--entry <file>=<path>]...]...
         [--alias <name>=<key>]... [--arg <argument>]... [--output <path>=<output>]...
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


def _build_link(source):
  """The relative target of the build's own link at `source`, if it is one; else None."""
  if not os.path.islink(source):
    return None
  target = os.readlink(source)
  if not os.path.isabs(target):
    return target
  if os.path.islink(target) and not os.path.isabs(os.readlink(target)):
    return os.readlink(target)
  return None


def _copy(source, destination):
  """Copies a file, or makes a link of the build's again; a directory with its contents."""
  link = _build_link(source)
  if link is not None:
    if os.path.lexists(destination):
      os.remove(destination)
    os.symlink(link, destination)
    return
  if os.path.isdir(source):
    os.makedirs(destination, exist_ok=True)
    for name in sorted(os.listdir(source)):
      _copy(os.path.join(source, name), os.path.join(destination, name))
    return
  os.makedirs(os.path.dirname(destination), exist_ok=True)
  shutil.copyfile(source, destination)
  shutil.copymode(source, destination)


def _relink_frameworks(root):
  """Makes a versioned framework bundle's directory links again where a copy stands in for one.

  As assemble_directory.py does: a directory output's links to directories
  reach a sandbox as directories (Bazel lists a tree artifact's files through
  them), and the recipe's scripts want the bundle's links (sky_utils'
  _regenerate_symlinks bails out when the top-level binary is a link, which
  it still is). Versions/Current becomes the link to the one version, each
  top-level copy of a version's item the link to it under Versions/Current.
  """
  for directory, subdirectories, _ in os.walk(root):
    if not directory.endswith('.framework'):
      continue
    versions = os.path.join(directory, 'Versions')
    if not os.path.isdir(versions) or os.path.islink(versions):
      continue
    current = os.path.join(versions, 'Current')
    if os.path.islink(current):
      version = os.readlink(current)
    else:
      names = [n for n in os.listdir(versions) if n != 'Current']
      if len(names) != 1:
        continue
      version = names[0]
      if os.path.lexists(current):
        shutil.rmtree(current)
      os.symlink(version, current)
    for item in os.listdir(os.path.join(versions, version)):
      top = os.path.join(directory, item)
      if not os.path.lexists(top) or os.path.islink(top):
        continue
      if os.path.isdir(top):
        shutil.rmtree(top)
      else:
        os.remove(top)
      os.symlink(os.path.join('Versions', 'Current', item), top)
    subdirectories[:] = []


def main(argv):
  args = _expanded(argv[1:])
  script = None
  builds = {}  # key -> [(file, path)]
  current = None
  aliases = []
  script_args = []
  outputs = []
  i = 0
  while i < len(args):
    option, value = args[i], args[i + 1]
    if option == '--script':
      script = value
    elif option == '--build':
      current = value
      builds[current] = []
    elif option == '--entry':
      if current is None:
        sys.exit('universal.py: --entry before any --build')
      builds[current].append(tuple(value.split('=', 1)))
    elif option == '--alias':
      aliases.append(tuple(value.split('=', 1)))
    elif option == '--arg':
      script_args.append(value)
    elif option == '--output':
      outputs.append(tuple(value.split('=', 1)))
    else:
      sys.exit('universal.py: unknown option %s' % option)
    i += 2
  if not (script and builds and script_args and outputs):
    sys.exit('universal.py: --script, a --build, --arg and --output are required')

  with tempfile.TemporaryDirectory() as scratch:
    directories = {}
    for key, entries in builds.items():
      root = os.path.join(scratch, key)
      os.makedirs(root)
      for source, path in entries:
        _copy(source, os.path.join(root, path))
      _relink_frameworks(root)
      directories[key] = root
    for name, key in aliases:
      os.symlink(directories[key], os.path.join(scratch, name))
      directories[name] = os.path.join(scratch, name)
    dst = os.path.join(scratch, 'dst')
    os.makedirs(dst)

    expanded = []
    for arg in script_args:
      arg = arg.replace('{dst}', dst)
      for key, directory in directories.items():
        arg = arg.replace('{build:%s}' % key, directory)
      expanded.append(arg)

    # The script as the recipe runs it: its own directory first on the
    # module path (it imports sky_utils and create_xcframework from there);
    # its `sys.exit(main())` is caught, so that the outputs are copied out.
    sys.path.insert(0, os.path.dirname(os.path.abspath(script)))
    sys.argv = [script] + expanded
    try:
      runpy.run_path(script, run_name='__main__')
    except SystemExit as exit:
      if exit.code not in (None, 0):
        sys.exit(exit.code)

    for path, output in outputs:
      source = os.path.join(dst, path)
      if not os.path.lexists(source):
        sys.exit('universal.py: %s wrote no %s' % (script, path))
      if os.path.isdir(output):
        shutil.rmtree(output)
      elif os.path.lexists(output):
        os.remove(output)
      _copy(source, output)


if __name__ == '__main__':
  main(sys.argv)
