# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'jni_generator_py_tests',
      'type': 'none',
      'variables': {
        'stamp': '<(INTERMEDIATE_DIR)/jni_generator_py_tests.stamp',
      },
      'actions': [
        {
          'action_name': 'run_jni_generator_py_tests',
          'inputs': [
            'jni_generator.py',
            'jni_generator_tests.py',
            'java/src/org/chromium/example/jni_generator/SampleForTests.java',
            'golden_sample_for_tests_jni.h',
          ],
          'outputs': [
            '<(stamp)',
          ],
          'action': [
            'python', 'jni_generator_tests.py',
            '--stamp=<(stamp)',
          ],
        },
      ],
    },
    {
      'target_name': 'jni_sample_header',
      'type': 'none',
      'sources': [
        'java/src/org/chromium/example/jni_generator/SampleForTests.java',
      ],
      'variables': {
        'jni_gen_package': 'example',
      },
      'includes': [ '../../../build/jni_generator.gypi' ],
    },
    {
      'target_name': 'jni_sample_java',
      'type': 'none',
      'variables': {
        'java_in_dir': '../../../base/android/jni_generator/java',
      },
      'dependencies': [
        '<(DEPTH)/base/base.gyp:base_java',
      ],
      'includes': [ '../../../build/java.gypi' ],
    },
    {
      'target_name': 'jni_generator_tests',
      'type': 'executable',
      'dependencies': [
        '../../base.gyp:test_support_base',
        'jni_generator_py_tests',
        'jni_sample_header',
        'jni_sample_java',
      ],
      'sources': [
        'sample_for_tests.cc',
      ],
    },
  ],
}
