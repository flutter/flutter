# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'enable_coverage%': 0,
  },
  'conditions': [
    ['enable_coverage', {
        'target_defaults': {
          'defines': [
            'ENABLE_TEST_CODE_COVERAGE=1'
          ],
          'link_settings': {
            'xcode_settings': {
              'OTHER_LDFLAGS': [
                '-fprofile-arcs',
              ],
            },
          },
          'xcode_settings': {
            'OTHER_CFLAGS': [
              '-fprofile-arcs',
              '-ftest-coverage',
            ],
          },
        },
    }],
  ],
}

