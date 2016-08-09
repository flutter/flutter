# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to build APK-based browser test suites.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'test_suite_name_apk',
#   'type': 'none',
#   'variables': {
#     'test_suite_name': 'test_suite_name',  # string
#     'java_in_dir': 'path/to/java/dir',
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#

{
  'dependencies': [
    '<(DEPTH)/base/base.gyp:base_java',
    '<(DEPTH)/build/android/pylib/device/commands/commands.gyp:chromium_commands',
    '<(DEPTH)/build/android/pylib/remote/device/dummy/dummy.gyp:remote_device_dummy_apk',
    '<(DEPTH)/testing/android/appurify_support.gyp:appurify_support_java',
    '<(DEPTH)/testing/android/native_test.gyp:native_test_java',
    '<(DEPTH)/tools/android/android_tools.gyp:android_tools',
  ],
  'conditions': [
     ['OS == "android"', {
       'variables': {
         # These are used to configure java_apk.gypi included below.
         'apk_name': '<(test_suite_name)',
         'intermediate_dir': '<(PRODUCT_DIR)/<(test_suite_name)_apk',
         'final_apk_path': '<(intermediate_dir)/<(test_suite_name)-debug.apk',
         'native_lib_target': 'lib<(test_suite_name)',
         # TODO(yfriedman, cjhopman): Support managed installs for gtests.
         'gyp_managed_install': 0,
       },
       'includes': [ 'java_apk.gypi' ],
     }],  # 'OS == "android"
  ],  # conditions
}
