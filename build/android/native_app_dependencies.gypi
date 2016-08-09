# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to strip and place dependent shared libraries required by a native binary in a
# single folder that can later be pushed to the device.
#
# NOTE: consider packaging your binary as an apk instead of running a native
# library.
#
# To use this, create a gyp target with the following form:
#  {
#    'target_name': 'target_that_depends_on_my_binary',
#    'type': 'none',
#    'dependencies': [
#      'my_binary',
#    ],
#    'variables': {
#      'native_binary': '<(PRODUCT_DIR)/my_binary',
#      'output_dir': 'location to place binary and dependent libraries'
#    },
#    'includes': [ '../../build/android/native_app_dependencies.gypi' ],
#  },
#

{
  'variables': {
    'include_main_binary%': 1,
  },
  'conditions': [
      ['component == "shared_library"', {
        'dependencies': [
          '<(DEPTH)/build/android/setup.gyp:copy_system_libraries',
        ],
        'variables': {
          'intermediate_dir': '<(PRODUCT_DIR)/<(_target_name)',
          'ordered_libraries_file': '<(intermediate_dir)/native_libraries.json',
        },
        'actions': [
          {
            'variables': {
              'input_libraries': ['<(native_binary)'],
            },
            'includes': ['../../build/android/write_ordered_libraries.gypi'],
          },
          {
            'action_name': 'stripping native libraries',
            'variables': {
              'stripped_libraries_dir%': '<(output_dir)',
              'input_paths': ['<(native_binary)'],
              'stamp': '<(intermediate_dir)/strip.stamp',
            },
            'includes': ['../../build/android/strip_native_libraries.gypi'],
          },
        ],
      }],
      ['include_main_binary==1', {
        'copies': [
          {
            'destination': '<(output_dir)',
            'files': [ '<(native_binary)' ],
          }
        ],
      }],
  ],
}
