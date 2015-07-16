# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libxml',
      'type': 'static_library',
      'sources': [
        'chromium/libxml_utils.h',
        'chromium/libxml_utils.cc',
      ],
      'cflags': [
        '<!@(pkg-config --cflags libxml-2.0)',
      ],
      'defines': [
        'USE_SYSTEM_LIBXML',
      ],
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags libxml-2.0)',
        ],
        'defines': [
          'USE_SYSTEM_LIBXML',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other libxml-2.0)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l libxml-2.0)',
        ],
      },
    },
  ],
}
