# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN: //third_party/junit:hamcrest
      'target_name': 'hamcrest_jar',
      'type': 'none',
      'variables': {
        'jar_path': 'src/lib/hamcrest-core-1.1.jar',
        'enable_errorprone': '0',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
    {
      # GN: //third_party/junit:junit
      'target_name': 'junit_jar',
      'type': 'none',
      'dependencies': [
        'hamcrest_jar',
      ],
      'variables': {
        'src_paths': [ 'src/src/main/java' ],
        'enable_errorprone': '0',
      },
      'includes': [
        '../../build/host_jar.gypi',
      ],
    },
  ],
}

