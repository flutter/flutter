# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'iccjpeg',
      'type': 'static_library',
      'dependencies': [
        '<(libjpeg_gyp_path):libjpeg',
      ],
      'sources': [
        'iccjpeg.c',
        'iccjpeg.h',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '.',
        ],
      },
    },
  ],
}
