# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'conditions': [
    ['OS=="android"', {
      'targets': [
        {
          'target_name': 'appurify_support_java',
          'type': 'none',
          'variables': {
            'java_in_dir': '../../testing/android/appurify_support/java',
          },
          'includes': [
            '../../build/java.gypi',
          ],
        },
      ],
    }],
  ],
}
