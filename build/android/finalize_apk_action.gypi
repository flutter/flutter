# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to provide an action that
# signs and zipaligns an APK.
#
# To use this, create a gyp action with the following form:
#  {
#    'action_name': 'some descriptive action name',
#    'variables': {
#      'input_apk_path': 'relative/path/to/input.apk',
#      'output_apk_path': 'relative/path/to/output.apk',
#    },
#    'includes': [ '../../build/android/finalize_apk_action.gypi' ],
#  },
#

{
  'message': 'Signing/aligning <(_target_name) APK: <(input_apk_path)',
  'variables': {
    'keystore_path%': '<(DEPTH)/build/android/ant/chromium-debug.keystore',
    'keystore_name%': 'chromiumdebugkey',
    'keystore_password%': 'chromium',
    'zipalign_path%': '<(android_sdk_tools)/zipalign',
    'rezip_apk_jar_path%': '<(PRODUCT_DIR)/lib.java/rezip_apk.jar',
    'load_library_from_zip%': 0,
  },
  'inputs': [
    '<(DEPTH)/build/android/gyp/finalize_apk.py',
    '<(DEPTH)/build/android/gyp/util/build_utils.py',
    '<(keystore_path)',
    '<(input_apk_path)',
  ],
  'outputs': [
    '<(output_apk_path)',
  ],
  'action': [
    'python', '<(DEPTH)/build/android/gyp/finalize_apk.py',
    '--zipalign-path=<(zipalign_path)',
    '--unsigned-apk-path=<(input_apk_path)',
    '--final-apk-path=<(output_apk_path)',
    '--key-path=<(keystore_path)',
    '--key-name=<(keystore_name)',
    '--key-passwd=<(keystore_password)',
    '--load-library-from-zip=<(load_library_from_zip)',
    '--rezip-apk-jar-path=<(rezip_apk_jar_path)',
  ],
}
