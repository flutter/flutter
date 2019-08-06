# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Small utility function to find depot_tools and add it to the python path.

Will throw an ImportError exception if depot_tools can't be found since it
imports breakpad.
"""

import os
import sys


def IsRealDepotTools(path):
  return os.path.isfile(os.path.join(path, 'gclient.py'))


def add_depot_tools_to_path():
  """Search for depot_tools and add it to sys.path."""
  # First look if depot_tools is already in PYTHONPATH.
  for i in sys.path:
    if i.rstrip(os.sep).endswith('depot_tools') and IsRealDepotTools(i):
      return i
  # Then look if depot_tools is in PATH, common case.
  for i in os.environ['PATH'].split(os.pathsep):
    if IsRealDepotTools(i):
      sys.path.append(i.rstrip(os.sep))
      return i
  # Rare case, it's not even in PATH, look upward up to root.
  root_dir = os.path.dirname(os.path.abspath(__file__))
  previous_dir = os.path.abspath(__file__)
  while root_dir and root_dir != previous_dir:
    i = os.path.join(root_dir, 'depot_tools')
    if IsRealDepotTools(i):
      sys.path.append(i)
      return i
    previous_dir = root_dir
    root_dir = os.path.dirname(root_dir)
  print >> sys.stderr, 'Failed to find depot_tools'
  return None

add_depot_tools_to_path()

# pylint: disable=W0611
import breakpad
