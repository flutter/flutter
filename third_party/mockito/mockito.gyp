# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN: //third_party/mockito:cglib_and_asm_java
      'target_name': 'cglib_and_asm_jar',
      'type': 'none',
      'variables': {
        'jar_path': 'src/lib/repackaged/cglib-and-asm-1.0.jar',
        'enable_errorprone': '0',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
    {
      # GN: //third_party/mockito:objenesis_java
      'target_name': 'objenesis_jar',
      'type': 'none',
      'variables': {
        'jar_path': 'src/lib/run/objenesis-2.1.jar',
        'enable_errorprone': '0',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ]
    },
    {
      # GN: //third_party/mockito:mockito_java
      'target_name': 'mockito_jar',
      'type': 'none',
      'dependencies': [
        'cglib_and_asm_jar',
        'objenesis_jar',
        '../junit/junit.gyp:junit_jar',
      ],
      'variables': {
        'src_paths': [ 'src/src' ],
        'enable_errorprone': '0',
      },
      'includes': [
        '../../build/host_jar.gypi',
      ],
    },
  ],
}

