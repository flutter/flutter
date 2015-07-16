# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Supports inferring locations of files in default checkout layouts.

These functions allow devtools scripts to work out-of-the-box with regular Mojo
checkouts.
"""

import os.path


def _lowest_ancestor_containing_relpath(relpath):
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


def infer_default_paths(is_android, is_debug, target_cpu):
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

  root_path = _lowest_ancestor_containing_relpath(out_build_dir)
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
