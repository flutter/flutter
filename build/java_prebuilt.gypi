# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to package prebuilt Java JARs in a consistent manner.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my-package_java',
#   'type': 'none',
#   'variables': {
#     'jar_path': 'path/to/your.jar',
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#
# Required variables:
#  jar_path - The path to the prebuilt Java JAR file.

{
  'dependencies': [
    '<(DEPTH)/build/android/setup.gyp:build_output_dirs'
  ],
  'variables': {
    'dex_path': '<(PRODUCT_DIR)/lib.java/<(_target_name).dex.jar',
    'intermediate_dir': '<(SHARED_INTERMEDIATE_DIR)/<(_target_name)',
    'android_jar': '<(android_sdk)/android.jar',
    'input_jars_paths': [ '<(android_jar)' ],
    'neverlink%': 0,
    'proguard_config%': '',
    'proguard_preprocess%': '0',
    'variables': {
      'variables': {
        'proguard_preprocess%': 0,
      },
      'conditions': [
        ['proguard_preprocess == 1', {
          'dex_input_jar_path': '<(intermediate_dir)/<(_target_name).pre.jar'
        }, {
          'dex_input_jar_path': '<(jar_path)'
        }],
      ],
    },
    'dex_input_jar_path': '<(dex_input_jar_path)',
  },
  'all_dependent_settings': {
    'variables': {
      'input_jars_paths': ['<(dex_input_jar_path)'],
      'conditions': [
        ['neverlink == 1', {
          'library_dexed_jars_paths': [],
        }, {
          'library_dexed_jars_paths': ['<(dex_path)'],
        }],
      ],
    },
  },
  'conditions' : [
    ['proguard_preprocess == 1', {
      'actions': [
        {
          'action_name': 'proguard_<(_target_name)',
          'message': 'Proguard preprocessing <(_target_name) jar',
          'inputs': [
            '<(android_sdk_root)/tools/proguard/lib/proguard.jar',
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/proguard.py',
            '<(jar_path)',
            '<(proguard_config)',
          ],
          'outputs': [
            '<(dex_input_jar_path)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/proguard.py',
            '--proguard-path=<(android_sdk_root)/tools/proguard/lib/proguard.jar',
            '--input-path=<(jar_path)',
            '--output-path=<(dex_input_jar_path)',
            '--proguard-config=<(proguard_config)',
            '--classpath=>(input_jars_paths)',
          ]
        },
      ],
    }],
    ['neverlink == 0', {
      'actions': [
        {
          'action_name': 'dex_<(_target_name)',
          'message': 'Dexing <(_target_name) jar',
          'variables': {
            'dex_input_paths': [
              '<(dex_input_jar_path)',
            ],
            'output_path': '<(dex_path)',
          },
          'includes': [ 'android/dex_action.gypi' ],
        },
      ],
    }],
  ],
}
