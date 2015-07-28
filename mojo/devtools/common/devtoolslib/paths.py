# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Supports inferring locations of files in default checkout layouts.

These functions allow devtools scripts to work out-of-the-box with regular Mojo
checkouts.
"""

import os.path
import sys


def find_ancestor_with(relpath):
  """Returns the lowest ancestor of this file that contains |relpath|."""
  cur_dir_path = os.path.abspath(os.path.dirname(__file__))
  while True:
    if os.path.exists(os.path.join(cur_dir_path, relpath)):
      return cur_dir_path

    next_dir_path = os.path.dirname(cur_dir_path)
    if next_dir_path != cur_dir_path:
      cur_dir_path = next_dir_path
    else:
      return None


def infer_mojo_paths(is_android, is_debug, target_cpu):
  """Infers the locations of select build output artifacts in a regular Mojo
  checkout.

  Returns:
    Tuple of path dictionary, error message. Only one of the two will be
    not-None.
  """
  build_dir = (('android_' if is_android else '') +
               (target_cpu + '_' if target_cpu else '') +
               ('Debug' if is_debug else 'Release'))
  out_build_dir = os.path.join('out', build_dir)

  root_path = find_ancestor_with(out_build_dir)
  if not root_path:
    return None, ('Failed to find build directory: ' + out_build_dir)

  paths = {}
  paths['root'] = root_path
  build_dir_path = os.path.join(root_path, out_build_dir)
  paths['build'] = build_dir_path
  if is_android:
    paths['shell'] = os.path.join(build_dir_path, 'apks', 'MojoShell.apk')
    paths['adb'] = os.path.join(root_path, 'third_party', 'android_tools',
                                'sdk', 'platform-tools', 'adb')
  else:
    paths['shell'] = os.path.join(build_dir_path, 'mojo_shell')

  paths['sky_packages'] = os.path.join(build_dir_path, 'gen', 'dart-pkg',
                                       'packages')
  return paths, None


# Based on Chromium //tools/find_depot_tools.py.
def find_depot_tools():
  """Searches for depot_tools.

  Returns:
    Path to the depot_tools checkout present on the machine, None if not found.
  """
  def _is_real_depot_tools(path):
    return os.path.isfile(os.path.join(path, 'gclient.py'))

  # First look if depot_tools is already in PYTHONPATH.
  for i in sys.path:
    if i.rstrip(os.sep).endswith('depot_tools') and _is_real_depot_tools(i):
      return i
  # Then look if depot_tools is in PATH, common case.
  for i in os.environ['PATH'].split(os.pathsep):
    if _is_real_depot_tools(i):
      return i
  # Rare case, it's not even in PATH, look upward up to root.
  root_dir = os.path.dirname(os.path.abspath(__file__))
  previous_dir = os.path.abspath(__file__)
  while root_dir and root_dir != previous_dir:
    i = os.path.join(root_dir, 'depot_tools')
    if _is_real_depot_tools(i):
      return i
    previous_dir = root_dir
    root_dir = os.path.dirname(root_dir)
  return None
