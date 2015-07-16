# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import sys
import sysconfig

def main():
  """Command line utility to retrieve compilation options for python modules'
  """
  parser = argparse.ArgumentParser(
      description='Retrieves compilation options for python modules.')
  parser.add_argument('--libraries', help='Returns libraries',
                      action='store_true')
  parser.add_argument('--includes', help='Returns includes',
                      action='store_true')
  parser.add_argument('--library_dirs', help='Returns library_dirs',
                      action='store_true')
  opts = parser.parse_args()

  result = []

  if opts.libraries:
    python_lib = sysconfig.get_config_var('LDLIBRARY')
    if python_lib.endswith(".so"):
      python_lib = python_lib[:-3]
    if python_lib.startswith("lib"):
      python_lib = python_lib[3:]

    result.append(python_lib)

  if opts.includes:
    result.append(sysconfig.get_config_var('INCLUDEPY'))

  if opts.library_dirs:
    result.append(sysconfig.get_config_var('BINLIBDEST'))

  for x in result:
    print x

if __name__ == '__main__':
  main()
