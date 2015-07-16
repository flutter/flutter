# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libjpeg',
      'type': 'none',
      'direct_dependent_settings': {
        'defines': [
          'USE_SYSTEM_LIBJPEG',
        ],
        'conditions': [
          ['os_bsd==1', {
            'include_dirs': [
              '/usr/local/include',
            ],
          }],
        ],
      },
      'link_settings': {
        'libraries': [
          '-ljpeg',
        ],
      },
    }
  ],
}
