# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libusb',
      'type': 'none',
      'variables': {
        'headers_root_path': 'src/libusb',
        'header_filenames': [
          'libusb.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags libusb-1.0)',
        ],
        'link_settings': {
          'ldflags': [
            '<!@(pkg-config --libs-only-L --libs-only-other libusb-1.0)',
          ],
          'libraries': [
            '<!@(pkg-config --libs-only-l libusb-1.0)',
          ],
        },
      },
    },
  ],
}
