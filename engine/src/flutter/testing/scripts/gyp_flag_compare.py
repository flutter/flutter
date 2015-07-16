#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Wrap //tools/gn/bin/gyp_flag_compare.py for the bots.

This script wraps the GN test script in the facade needed for the
'ScriptTest' step class of the chromium recipe_module
(see scripts/slave/recipe_modules/chromium/steps.py in the build repo.

The script takes N arguments, for the N targets to compare flags for.
"""

import json
import os
import sys


import common


def main_run(args):
  rc = common.run_command([sys.executable,
                           os.path.join(common.SRC_DIR,
                                        'tools', 'gn', 'bin',
                                        'gyp_flag_compare.py')] + args.args)

  # TODO(dpranke): Figure out how to get a list of failures out of
  # gyp_flag_compare?
  json.dump({
      'valid': True,
      'failures': ['compare_failed'] if rc else [],
  }, args.output)

  return rc


def main_compile_targets(args):
  # TODO(dpranke): Figure out how to get args.args plumbed through to here.
  json.dump([], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
