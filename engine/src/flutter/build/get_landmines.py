#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This file emits the list of reasons why a particular build needs to be clobbered
(or a list of 'landmines').
"""

import sys

import landmine_utils


builder = landmine_utils.builder
distributor = landmine_utils.distributor
gyp_defines = landmine_utils.gyp_defines
gyp_msvs_version = landmine_utils.gyp_msvs_version
platform = landmine_utils.platform


def print_landmines():
  """
  ALL LANDMINES ARE EMITTED FROM HERE.
  """
  # DO NOT add landmines as part of a regular CL. Landmines are a last-effort
  # bandaid fix if a CL that got landed has a build dependency bug and all bots
  # need to be cleaned up. If you're writing a new CL that causes build
  # dependency problems, fix the dependency problems instead of adding a
  # landmine.

  print 'Lets start a new landmines file.'


def main():
  print_landmines()
  return 0


if __name__ == '__main__':
  sys.exit(main())
