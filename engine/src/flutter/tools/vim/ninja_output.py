# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


import os
import os.path
import re


def GetNinjaOutputDirectory(chrome_root, configuration=None):
  """Returns <chrome_root>/<output_dir>/(Release|Debug).

  The output_dir is detected in the following ways, in order of precedence:
  1. CHROMIUM_OUT_DIR environment variable.
  2. GYP_GENERATOR_FLAGS environment variable output_dir property.
  3. Symlink target, if src/out is a symlink.
  4. Most recently modified (e.g. built) directory called out or out_*.

  The configuration chosen is the one most recently generated/built, but can be
  overriden via the <configuration> parameter."""

  output_dirs = []
  if ('CHROMIUM_OUT_DIR' in os.environ and
      os.path.isdir(os.path.join(chrome_root, os.environ['CHROMIUM_OUT_DIR']))):
    output_dirs = [os.environ['CHROMIUM_OUT_DIR']]
  if not output_dirs:
    generator_flags = os.getenv('GYP_GENERATOR_FLAGS', '').split(' ')
    for flag in generator_flags:
      name_value = flag.split('=', 1)
      if (len(name_value) == 2 and name_value[0] == 'output_dir' and
          os.path.isdir(os.path.join(chrome_root, name_value[1]))):
        output_dirs = [name_value[1]]
  if not output_dirs:
    out = os.path.join(chrome_root, 'out')
    if os.path.islink(out):
      out_target = os.path.join(os.path.dirname(out), os.readlink(out))
      if os.path.exists(out_target):
        output_dirs = [out_target]
  if not output_dirs:
    for f in os.listdir(chrome_root):
      if (re.match('out(?:$|_)', f) and
          os.path.isdir(os.path.join(chrome_root, f))):
        output_dirs.append(f)

  configs = [configuration] if configuration else ['Debug', 'Release']
  output_paths = [os.path.join(chrome_root, out_dir, config)
                  for out_dir in output_dirs for config in configs]

  def approx_directory_mtime(path):
    if not os.path.exists(path):
      return -1
    # This is a heuristic; don't recurse into subdirectories.
    paths = [path] + [os.path.join(path, f) for f in os.listdir(path)]
    return max(os.path.getmtime(p) for p in paths)

  return max(output_paths, key=approx_directory_mtime)
