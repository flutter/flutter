# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Build the rezip build tool.
{
  'targets': [
    {
      # GN: //build/android/rezip:rezip
      'target_name': 'rezip_apk_jar',
      'type': 'none',
      'variables': {
        'java_in_dir': 'rezip',
        'compile_stamp': '<(SHARED_INTERMEDIATE_DIR)/<(_target_name)/compile.stamp',
        'javac_jar_path': '<(PRODUCT_DIR)/lib.java/rezip_apk.jar',
      },
      'actions': [
        {
          'action_name': 'javac_<(_target_name)',
          'message': 'Compiling <(_target_name) java sources',
          'variables': {
            'java_sources': ['>!@(find >(java_in_dir) -name "*.java")'],
          },
          'inputs': [
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/javac.py',
            '>@(java_sources)',
          ],
          'outputs': [
            '<(compile_stamp)',
            '<(javac_jar_path)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/javac.py',
            '--classpath=',
            '--classes-dir=<(SHARED_INTERMEDIATE_DIR)/<(_target_name)',
            '--jar-path=<(javac_jar_path)',
            '--stamp=<(compile_stamp)',
            '>@(java_sources)',
          ]
        },
      ],
    }
  ],
}
