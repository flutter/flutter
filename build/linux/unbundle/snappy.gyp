# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'snappy',
      'type': 'none',
      'variables': {
        'headers_root_path': 'src',
        'header_filenames': [
          'snappy-c.h',
          'snappy-sinksource.h',
          'snappy-stubs-public.h',
          'snappy.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'link_settings': {
        'libraries': [
          '-lsnappy',
        ],
      },
    },
  ],
}
