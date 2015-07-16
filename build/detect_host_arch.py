#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Outputs host CPU architecture in format recognized by gyp."""

import platform
import re
import sys


def HostArch():
  """Returns the host architecture with a predictable string."""
  host_arch = platform.machine()

  # Convert machine type to format recognized by gyp.
  if re.match(r'i.86', host_arch) or host_arch == 'i86pc':
    host_arch = 'ia32'
  elif host_arch in ['x86_64', 'amd64']:
    host_arch = 'x64'
  elif host_arch.startswith('arm'):
    host_arch = 'arm'

  # platform.machine is based on running kernel. It's possible to use 64-bit
  # kernel with 32-bit userland, e.g. to give linker slightly more memory.
  # Distinguish between different userland bitness by querying
  # the python binary.
  if host_arch == 'x64' and platform.architecture()[0] == '32bit':
    host_arch = 'ia32'

  return host_arch

def DoMain(_):
  """Hook to be called from gyp without starting a separate python
  interpreter."""
  return HostArch()

if __name__ == '__main__':
  print DoMain([])
