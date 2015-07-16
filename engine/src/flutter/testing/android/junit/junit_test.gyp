# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN: //testing/android/junit:junit_test_support
      'target_name': 'junit_test_support',
      'type': 'none',
      'dependencies': [
        '../../../third_party/junit/junit.gyp:junit_jar',
        '../../../third_party/mockito/mockito.gyp:mockito_jar',
        '../../../third_party/robolectric/robolectric.gyp:robolectric_jar'
      ],
      'variables': {
        'src_paths': [
          'java/src',
        ],
      },
      'includes': [
        '../../../build/host_jar.gypi',
      ],
    },
    {
      # GN: //testing/android/junit:junit_unittests
      'target_name': 'junit_unit_tests',
      'type': 'none',
      'dependencies': [
        'junit_test_support',
      ],
      'variables': {
        'main_class': 'org.chromium.testing.local.JunitTestMain',
        'src_paths': [
          'javatests/src',
        ],
      },
      'includes': [
        '../../../build/host_jar.gypi',
      ],
    },
  ],
}
