# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN: //third_party/robolectric:android-all-4.3_r2-robolectric-0
      'target_name': 'android-all-4.3_r2-robolectric-0',
      'type': 'none',
      'variables': {
        'jar_path': 'lib/android-all-4.3_r2-robolectric-0.jar',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
    {
      # GN: //third_party/robolectric:tagsoup-1.2
      'target_name': 'tagsoup-1.2',
      'type': 'none',
      'variables': {
        'jar_path': 'lib/tagsoup-1.2.jar',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
    {
      # GN: //third_party/robolectric:json-20080701
      'target_name': 'json-20080701',
      'type': 'none',
      'variables': {
        'jar_path': 'lib/json-20080701.jar',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
    {
      # GN: //third_party/robolectric:robolectric_java
      'target_name': 'robolectric_jar',
      'type': 'none',
      'dependencies': [
        'android-all-4.3_r2-robolectric-0',
        'tagsoup-1.2',
        'json-20080701',
      ],
      'variables': {
        'jar_path': 'lib/robolectric-2.4-jar-with-dependencies.jar',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
  ],
}

