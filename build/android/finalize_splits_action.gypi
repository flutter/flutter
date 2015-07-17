# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to provide an action that
# signs and zipaligns split APKs.
#
# Required variables:
#  apk_name - Base name of the apk.
# Optional variables:
#  density_splits - Whether to process density splits
#  language_splits - Whether to language splits

{
  'variables': {
    'keystore_path%': '<(DEPTH)/build/android/ant/chromium-debug.keystore',
    'keystore_name%': 'chromiumdebugkey',
    'keystore_password%': 'chromium',
    'zipalign_path%': '<(android_sdk_tools)/zipalign',
    'density_splits%': 0,
    'language_splits%': [],
    'resource_packaged_apk_name': '<(apk_name)-resources.ap_',
    'resource_packaged_apk_path': '<(intermediate_dir)/<(resource_packaged_apk_name)',
    'base_output_path': '<(PRODUCT_DIR)/apks/<(apk_name)',
  },
  'inputs': [
    '<(DEPTH)/build/android/gyp/finalize_splits.py',
    '<(DEPTH)/build/android/gyp/finalize_apk.py',
    '<(DEPTH)/build/android/gyp/util/build_utils.py',
    '<(keystore_path)',
  ],
  'action': [
    'python', '<(DEPTH)/build/android/gyp/finalize_splits.py',
    '--resource-packaged-apk-path=<(resource_packaged_apk_path)',
    '--base-output-path=<(base_output_path)',
    '--zipalign-path=<(zipalign_path)',
    '--key-path=<(keystore_path)',
    '--key-name=<(keystore_name)',
    '--key-passwd=<(keystore_password)',
  ],
  'conditions': [
    ['density_splits == 1', {
      'message': 'Signing/aligning <(_target_name) density splits',
      'inputs': [
        '<(resource_packaged_apk_path)_hdpi',
        '<(resource_packaged_apk_path)_xhdpi',
        '<(resource_packaged_apk_path)_xxhdpi',
        '<(resource_packaged_apk_path)_xxxhdpi',
        '<(resource_packaged_apk_path)_tvdpi',
      ],
      'outputs': [
        '<(base_output_path)-density-hdpi.apk',
        '<(base_output_path)-density-xhdpi.apk',
        '<(base_output_path)-density-xxhdpi.apk',
        '<(base_output_path)-density-xxxhdpi.apk',
        '<(base_output_path)-density-tvdpi.apk',
      ],
      'action': [
        '--densities=hdpi,xhdpi,xxhdpi,xxxhdpi,tvdpi',
      ],
    }],
    ['language_splits != []', {
      'message': 'Signing/aligning <(_target_name) language splits',
      'inputs': [
        "<!@(python <(DEPTH)/build/apply_locales.py '<(resource_packaged_apk_path)_ZZLOCALE' <(language_splits))",
      ],
      'outputs': [
        "<!@(python <(DEPTH)/build/apply_locales.py '<(base_output_path)-lang-ZZLOCALE.apk' <(language_splits))",
      ],
      'action': [
        '--languages=<(language_splits)',
      ],
    }],
  ],
}

