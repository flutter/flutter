# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Creates a resources.zip with locale.pak files placed into appropriate
# resource configs (e.g. en-GB.pak -> res/raw-en/en_gb.pak). Also generates
# a locale_paks TypedArray so that resource files can be enumerated at runtime.
#
# If this target is included in the deps of an android resources/library/apk,
# the resources will be included with that target.
#
# Variables:
#   locale_pak_files - List of .pak files to process.
#     Names must be of the form "en.pak" or "en-US.pak".
#
# Example
#  {
#    'target_name': 'my_locale_resources',
#    'type': 'none',
#    'variables': {
#      'locale_paks_files': ['path1/fr.pak'],
#    },
#    'includes': [ '../build/android/locale_pak_resources.gypi' ],
#  },
#
{
  'variables': {
    'resources_zip_path': '<(PRODUCT_DIR)/res.java/<(_target_name).zip',
  },
  'all_dependent_settings': {
    'variables': {
      'additional_input_paths': ['<(resources_zip_path)'],
      'dependencies_res_zip_paths': ['<(resources_zip_path)'],
    },
  },
  'actions': [{
    'action_name': '<(_target_name)_locale_pak_resources',
    'inputs': [
      '<(DEPTH)/build/android/gyp/util/build_utils.py',
      '<(DEPTH)/build/android/gyp/locale_pak_resources.py',
      '<@(locale_pak_files)',
    ],
    'outputs': [
      '<(resources_zip_path)',
    ],
    'action': [
      'python', '<(DEPTH)/build/android/gyp/locale_pak_resources.py',
      '--locale-paks', '<(locale_pak_files)',
      '--resources-zip', '<(resources_zip_path)',
    ],
  }],
}
