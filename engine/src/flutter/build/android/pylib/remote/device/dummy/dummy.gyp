# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Running gtests on a remote device via am instrument requires both an "app"
# APK and a "test" APK with different package names. Our gtests only use one
# APK, so we build a dummy APK to upload as the app.

{
  'targets': [
    {
      # GN: //build/android/pylib/remote/device/dummy:remote_device_dummy_apk
      'target_name': 'remote_device_dummy_apk',
      'type': 'none',
      'variables': {
        'apk_name': 'remote_device_dummy',
        'java_in_dir': '.',
        'android_manifest_path': '../../../../../../build/android/AndroidManifest.xml',
      },
      'includes': [
        '../../../../../../build/java_apk.gypi',
      ]
    },
  ]
}
