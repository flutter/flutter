# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Sets up various automatic gyp environment variables. These are used by
gyp_chromium and landmines.py which run at different stages of runhooks. To
make sure settings are consistent between them, all setup should happen here.
"""

import gyp_helper
import os
import sys
import vs_toolchain

def SetEnvironment():
  """Sets defaults for GYP_* variables."""
  gyp_helper.apply_chromium_gyp_env()

  # Default to ninja on linux and windows, but only if no generator has
  # explicitly been set.
  # Also default to ninja on mac, but only when not building chrome/ios.
  # . -f / --format has precedence over the env var, no need to check for it
  # . set the env var only if it hasn't been set yet
  # . chromium.gyp_env has been applied to os.environ at this point already
  if sys.platform.startswith(('linux', 'win', 'freebsd')) and \
      not os.environ.get('GYP_GENERATORS'):
    os.environ['GYP_GENERATORS'] = 'ninja'
  elif sys.platform == 'darwin' and not os.environ.get('GYP_GENERATORS') and \
      not 'OS=ios' in os.environ.get('GYP_DEFINES', []):
    os.environ['GYP_GENERATORS'] = 'ninja'

  vs_toolchain.SetEnvironmentAndGetRuntimeDllDirs()
