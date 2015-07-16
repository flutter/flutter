# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to generate localized strings.xml from a grd file.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my-package_strings_grd',
#   'type': 'none',
#   'variables': {
#     'grd_file': 'path/to/grd/file',
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#
# Required variables:
#  grd_file - The path to the grd file to use.
{
  'variables': {
    'res_grit_dir': '<(INTERMEDIATE_DIR)/<(_target_name)/res_grit',
    'grit_grd_file': '<(grd_file)',
    'resource_zip_path': '<(PRODUCT_DIR)/res.java/<(_target_name).zip',
    'grit_additional_defines': ['-E', 'ANDROID_JAVA_TAGGED_ONLY=false'],
    'grit_out_dir': '<(res_grit_dir)',
    # resource_ids is unneeded since we don't generate .h headers.
    'grit_resource_ids': '',
    'grit_outputs': [
      '<!@pymod_do_main(grit_info <@(grit_defines) <@(grit_additional_defines) '
          '--outputs \'<(grit_out_dir)\' '
          '<(grit_grd_file) -f "<(grit_resource_ids)")',
          ]
  },
  'all_dependent_settings': {
    'variables': {
      'additional_input_paths': ['<(resource_zip_path)'],
      'dependencies_res_zip_paths': ['<(resource_zip_path)'],
    },
  },
  'actions': [
    {
      'action_name': 'generate_localized_strings_xml',
      'includes': ['../build/grit_action.gypi'],
    },
    {
      'action_name': 'create_resources_zip',
      'inputs': [
          '<(DEPTH)/build/android/gyp/zip.py',
          '<@(grit_outputs)',
      ],
      'outputs': [
          '<(resource_zip_path)',
      ],
      'action': [
          'python', '<(DEPTH)/build/android/gyp/zip.py',
          '--input-dir', '<(res_grit_dir)',
          '--output', '<(resource_zip_path)',
      ],
    }
  ],
}
