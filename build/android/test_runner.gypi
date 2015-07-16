# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generates a script in the output bin directory which runs the test
# target using the test runner script in build/android/pylib/test_runner.py.
#
# To use this, include this file in a gtest or instrumentation test target.
# {
#   'target_name': 'gtest',
#   'type': 'none',
#   'variables': {
#     'test_type': 'gtest',  # string
#     'test_suite_name': 'gtest_suite'  # string
#     'isolate_file': 'path/to/gtest.isolate'  # string
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#
# {
#   'target_name': 'instrumentation_apk',
#   'type': 'none',
#   'variables': {
#     'test_type': 'instrumentation',  # string
#     'apk_name': 'TestApk'  # string
#     'isolate_file': 'path/to/instrumentation_test.isolate'  # string
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#

{
  'variables': {
    'variables': {
      'isolate_file%': '',
    },
    'test_runner_args': ['--output-directory', '<(PRODUCT_DIR)'],
    'conditions': [
      ['test_type == "gtest"', {
        'test_runner_args': ['--suite', '<(test_suite_name)'],
        'script_name': 'run_<(test_suite_name)',
      }],
      ['test_type == "instrumentation"', {
        'test_runner_args': ['--test-apk', '<(apk_name)'],
        'script_name': 'run_<(_target_name)',
      }],
      ['isolate_file != ""', {
        'test_runner_args': ['--isolate-file-path', '<(isolate_file)']
      }],
    ],
  },
  'actions': [
    {
      'action_name': 'create_test_runner_script_<(script_name)',
      'message': 'Creating test runner script <(script_name)',
      'variables': {
        'script_output_path': '<(PRODUCT_DIR)/bin/<(script_name)',
      },
      'inputs': [
        '<(DEPTH)/build/android/gyp/create_test_runner_script.py',
      ],
      'outputs': [
        '<(script_output_path)'
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/create_test_runner_script.py',
        '--script-output-path=<(script_output_path)',
        '<(test_type)', '<@(test_runner_args)',
      ],
    },
  ],
}