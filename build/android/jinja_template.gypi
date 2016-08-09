# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to process one or more
# Jinja templates.
#
# To process a single template file, create a gyp target with the following
# form:
#  {
#    'target_name': 'chrome_shell_manifest',
#    'type': 'none',
#    'variables': {
#      'jinja_inputs': ['android/shell/java/AndroidManifest.xml'],
#      'jinja_output': '<(SHARED_INTERMEDIATE_DIR)/chrome_shell_manifest/AndroidManifest.xml',
#      'jinja_variables': ['app_name=ChromeShell'],
#    },
#    'includes': [ '../build/android/jinja_template.gypi' ],
#  },
#
# To process multiple template files and package the results into a zip file,
# create a gyp target with the following form:
#  {
#    'target_name': 'chrome_template_resources',
#    'type': 'none',
#    'variables': {
#       'jinja_inputs_base_dir': 'android/shell/java/res_template',
#       'jinja_inputs': [
#         '<(jinja_inputs_base_dir)/xml/searchable.xml',
#         '<(jinja_inputs_base_dir)/xml/syncadapter.xml',
#       ],
#       'jinja_outputs_zip': '<(PRODUCT_DIR)/res.java/<(_target_name).zip',
#       'jinja_variables': ['app_name=ChromeShell'],
#     },
#     'includes': [ '../build/android/jinja_template.gypi' ],
#   },
#

{
  'actions': [
    {
      'action_name': '<(_target_name)_jinja_template',
      'message': 'processing jinja template',
      'variables': {
        'jinja_output%': '',
        'jinja_outputs_zip%': '',
        'jinja_inputs_base_dir%': '',
        'jinja_includes%': [],
        'jinja_variables%': [],
        'jinja_args': [],
      },
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(DEPTH)/build/android/gyp/jinja_template.py',
        '<@(jinja_inputs)',
        '<@(jinja_includes)',
      ],
      'conditions': [
        ['jinja_output != ""', {
          'outputs': [ '<(jinja_output)' ],
          'variables': {
            'jinja_args': ['--output', '<(jinja_output)'],
          },
        }],
        ['jinja_outputs_zip != ""', {
          'outputs': [ '<(jinja_outputs_zip)' ],
          'variables': {
            'jinja_args': ['--outputs-zip', '<(jinja_outputs_zip)'],
          },
        }],
        ['jinja_inputs_base_dir != ""', {
          'variables': {
            'jinja_args': ['--inputs-base-dir', '<(jinja_inputs_base_dir)'],
          },
        }],
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/jinja_template.py',
        '--inputs', '<(jinja_inputs)',
        '--variables', '<(jinja_variables)',
        '<@(jinja_args)',
      ],
    },
  ],
}
