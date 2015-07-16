# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libpng',
      'type': 'none',
      'dependencies': [
        '../zlib/zlib.gyp:zlib',
      ],
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags libpng)',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other libpng)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l libpng)',
        ],
      },
      'variables': {
        'headers_root_path': '.',
        'header_filenames': [
          'png.h',
          'pngconf.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
    },
  ],
}
