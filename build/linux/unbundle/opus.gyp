# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'opus',
      'type': 'none',
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags opus)',
        ],
      },
      'variables': {
        'headers_root_path': 'src/include',
        'header_filenames': [
          'opus_custom.h',
          'opus_defines.h',
          'opus_multistream.h',
          'opus_types.h',
          'opus.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other opus)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l opus)',
        ],
      },
    },
  ],
}
