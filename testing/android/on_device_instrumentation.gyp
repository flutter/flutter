# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'conditions': [
    ['OS=="android"', {
      'variables' : {
        'driver_apk_name': 'OnDeviceInstrumentationDriver',
        'driver_apk_path': '<(PRODUCT_DIR)/apks/<(driver_apk_name).apk'
      },
      'targets': [
        {
          'target_name': 'reporter_java',
          'type': 'none',
          'dependencies': ['../../base/base.gyp:base_java'],
          'variables': {
            'java_in_dir': '../../testing/android/reporter/java',
          },
          'includes': [
            '../../build/java.gypi',
          ],
        },
        {
          'target_name': 'broker_java',
          'type': 'none',
          'variables': {
            'java_in_dir': '../../testing/android/broker/java',
          },
          'includes': [
            '../../build/java.gypi',
          ],
        },
        {
          'target_name': 'driver_apk',
          'type': 'none',
          'dependencies': [
            'broker_java',
            'reporter_java',
            'appurify_support.gyp:appurify_support_java',
          ],
          'variables': {
            'apk_name': '<(driver_apk_name)',
            'final_apk_path': '<(driver_apk_path)',
            'java_in_dir': '../../testing/android/driver/java',
          },
          'includes': [
            '../../build/java_apk.gypi',
          ],
        },
        {
          # This emulates gn's datadeps fields, allowing other APKs to declare
          # that they require that this APK be built without including the
          # driver's code.
          'target_name': 'require_driver_apk',
          'type': 'none',
          'actions': [
            {
              'action_name': 'require_<(driver_apk_name)',
              'message': 'Making sure <(driver_apk_path) has been built.',
              'variables': {
                'required_file': '<(PRODUCT_DIR)/driver_apk/<(driver_apk_name).apk.required',
              },
              'inputs': [
                '<(driver_apk_path)',
              ],
              'outputs': [
                '<(required_file)',
              ],
              'action': [
                'python', '../../build/android/gyp/touch.py', '<(required_file)',
              ],
            },
          ],
        },
      ],
    }],
  ],
}
