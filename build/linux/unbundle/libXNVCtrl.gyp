# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libXNVCtrl',
      'type': 'none',
      'variables': {
        'headers_root_path': '.',
        'header_filenames': [
          'NVCtrlLib.h',
          'NVCtrl.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'direct_dependent_settings': {
        'cflags': [
            '<!@(pkg-config --cflags libXNVCtrl)',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other libXNVCtrl)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l libXNVCtrl)',
        ],
      },
    }
  ],
}
