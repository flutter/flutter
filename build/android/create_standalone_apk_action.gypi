# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to provide an action that
# combines a directory of shared libraries and an incomplete APK into a
# standalone APK.
#
# To use this, create a gyp action with the following form:
#  {
#    'action_name': 'some descriptive action name',
#    'variables': {
#      'inputs': [ 'input_path1', 'input_path2' ],
#      'input_apk_path': '<(unsigned_apk_path)',
#      'output_apk_path': '<(unsigned_standalone_apk_path)',
#      'libraries_top_dir': '<(libraries_top_dir)',
#    },
#    'includes': [ 'relative/path/to/create_standalone_apk_action.gypi' ],
#  },

{
  'message': 'Creating standalone APK: <(output_apk_path)',
  'variables': {
    'inputs': [],
  },
  'inputs': [
    '<(DEPTH)/build/android/gyp/util/build_utils.py',
    '<(DEPTH)/build/android/gyp/create_standalone_apk.py',
    '<(input_apk_path)',
    '>@(inputs)',
  ],
  'outputs': [
    '<(output_apk_path)',
  ],
  'action': [
    'python', '<(DEPTH)/build/android/gyp/create_standalone_apk.py',
    '--libraries-top-dir=<(libraries_top_dir)',
    '--input-apk-path=<(input_apk_path)',
    '--output-apk-path=<(output_apk_path)',
  ],
}
