#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Determines if the VS xtree header has been patched to disable C4702."""

import os


def IsPatched():
  # TODO(scottmg): For now, just return if we're using the packaged toolchain
  # script (because we know it's patched). Another case could be added here to
  # query the active VS installation and actually check the contents of xtree.
  # http://crbug.com/346399.
  return int(os.environ.get('DEPOT_TOOLS_WIN_TOOLCHAIN', 1)) == 1


def DoMain(_):
  """Hook to be called from gyp without starting a separate python
  interpreter."""
  return "1" if IsPatched() else "0"


if __name__ == '__main__':
  print DoMain([])
