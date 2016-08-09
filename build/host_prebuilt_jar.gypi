# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule to
# copy a prebuilt JAR for use on a host to the output directory.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_prebuilt_jar',
#   'type': 'none',
#   'variables': {
#     'jar_path': 'path/to/prebuilt.jar',
#   },
#   'includes': [ 'path/to/this/gypi/file' ],
# }
#
# Required variables:
#   jar_path - The path to the prebuilt jar.

{
  'dependencies': [
  ],
  'variables': {
    'dest_path': '<(PRODUCT_DIR)/lib.java/<(_target_name).jar',
    'src_path': '<(jar_path)',
  },
  'all_dependent_settings': {
    'variables': {
      'input_jars_paths': [
        '<(dest_path)',
      ]
    },
  },
  'actions': [
    {
      'action_name': 'copy_prebuilt_jar',
      'message': 'Copy <(src_path) to <(dest_path)',
      'inputs': [
        '<(src_path)',
      ],
      'outputs': [
        '<(dest_path)',
      ],
      'action': [
        'python', '<(DEPTH)/build/cp.py', '<(src_path)', '<(dest_path)',
      ],
    }
  ]
}
