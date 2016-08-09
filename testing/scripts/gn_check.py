#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Wrap `gn check` for the bots.

This script wraps the `gn check` command in the facade needed for the
'ScriptTest' step class of the chromium recipe_module
(see scripts/slave/recipe_modules/chromium/steps.py in the build repo).

The script takes no arguments.
"""


import json
import os
import sys


import common


def main_run(args):
  if sys.platform == 'win32':
    exe = os.path.join(common.SRC_DIR, 'buildtools', 'win', 'gn.exe')
  elif sys.platform == 'mac':
    exe = os.path.join(common.SRC_DIR, 'buildtools', 'mac', 'gn')
  else:
    exe = os.path.join(common.SRC_DIR, 'buildtools', 'linux64', 'gn')

  rc = common.run_command([
      exe,
      '--root=%s' % common.SRC_DIR,
      'check',
      '//out/%s' % args.build_config_fs,
  ])

  # TODO(dpranke): Figure out how to get a list of failures out of gn check?
  json.dump({
      'valid': True,
      'failures': ['check_failed'] if rc else [],
  }, args.output)

  return rc


def main_compile_targets(args):
  json.dump([], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
