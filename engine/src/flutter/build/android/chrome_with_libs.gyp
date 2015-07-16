# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to add more loadable libs into Chrome_apk.
#
# This is useful when building Chrome_apk with some loadable modules which are
# not included in Chrome_apk.
# As an example, when building Chrome_apk with
# libpeer_target_type=loadable_module,
# the libpeerconnection.so is not included in Chrome_apk. To add the missing
# lib, follow the steps below:
# - Run gyp:
#     GYP_DEFINES="$GYP_DEFINES libpeer_target_type=loadable_module" CHROMIUM_GYP_FILE="build/android/chrome_with_libs.gyp" build/gyp_chromium
# - Build chrome_with_libs:
#     ninja (or make) chrome_with_libs
#
# This tool also allows replacing the loadable module with a new one via the
# following steps:
# - Build Chrome_apk with the gyp define:
#     GYP_DEFINES="$GYP_DEFINES libpeer_target_type=loadable_module" build/gyp_chromium
#     ninja (or make) Chrome_apk
# - Replace libpeerconnection.so with a new one:
#     cp the_new_one path/to/libpeerconnection.so
# - Run gyp:
#     GYP_DEFINES="$GYP_DEFINES libpeer_target_type=loadable_module" CHROMIUM_GYP_FILE="build/android/chrome_with_libs.gyp" build/gyp_chromium
# - Build chrome_with_libs:
#     ninja (or make) chrome_with_libs
{
  'targets': [
    {
      # An "All" target is required for a top-level gyp-file.
      'target_name': 'All',
      'type': 'none',
      'dependencies': [
        'chrome_with_libs',
      ],
    },
    {
      'target_name': 'chrome_with_libs',
      'type': 'none',
      'variables': {
        'intermediate_dir': '<(PRODUCT_DIR)/prebuilt_libs/',
        'chrome_unsigned_path': '<(PRODUCT_DIR)/chrome_apk/Chrome-unsigned.apk',
        'chrome_with_libs_unsigned': '<(intermediate_dir)/Chrome-with-libs-unsigned.apk',
        'chrome_with_libs_final': '<(PRODUCT_DIR)/apks/Chrome-with-libs.apk',
      },
      'dependencies': [
        '<(DEPTH)/clank/native/framework/clank.gyp:chrome_apk'
      ],
      'copies': [
        {
          'destination': '<(intermediate_dir)/lib/<(android_app_abi)',
          'files': [
            '<(PRODUCT_DIR)/libpeerconnection.so',
          ],
        },
      ],
      'actions': [
        {
          'action_name': 'put_libs_in_chrome',
          'variables': {
            'inputs': [
              '<(intermediate_dir)/lib/<(android_app_abi)/libpeerconnection.so',
            ],
            'input_apk_path': '<(chrome_unsigned_path)',
            'output_apk_path': '<(chrome_with_libs_unsigned)',
            'libraries_top_dir%': '<(intermediate_dir)',
          },
          'includes': [ 'create_standalone_apk_action.gypi' ],
        },
        {
          'action_name': 'finalize_chrome_with_libs',
          'variables': {
            'input_apk_path': '<(chrome_with_libs_unsigned)',
            'output_apk_path': '<(chrome_with_libs_final)',
          },
          'includes': [ 'finalize_apk_action.gypi'],
        },
      ],
    }],
}
