# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to build uiautomator dexed tests jar.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'test_suite_name',
#   'type': 'none',
#   'includes': ['path/to/this/gypi/file'],
# }
#

{
  'dependencies': [
    '<(DEPTH)/build/android/pylib/device/commands/commands.gyp:chromium_commands',
    '<(DEPTH)/tools/android/android_tools.gyp:android_tools',
  ],
  'variables': {
    'output_dex_path': '<(PRODUCT_DIR)/lib.java/<(_target_name).dex.jar',
  },
  'actions': [
    {
      'action_name': 'dex_<(_target_name)',
      'message': 'Dexing <(_target_name) jar',
      'variables': {
        'dex_input_paths': [
          '>@(library_dexed_jars_paths)',
        ],
        'output_path': '<(output_dex_path)',
      },
      'includes': [ 'android/dex_action.gypi' ],
    },
  ],
}
