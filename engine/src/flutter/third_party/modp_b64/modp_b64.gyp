# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'modp_b64',
      'type': 'static_library',
      'toolsets': ['host', 'target'],
      'sources': [
        'modp_b64.cc',
        'modp_b64.h',
        'modp_b64_data.h',
      ],
      'include_dirs': [
        '../..',
      ],
    },
  ],
  'conditions': [
    ['OS == "win" and target_arch=="ia32"', {
      # Even if we are building the browser for Win32, we need a few modules
      # to be built for Win64, and this is a prerequsite.
      'targets': [
        {
          'target_name': 'modp_b64_win64',
          'type': 'static_library',
          # We can't use dynamic_annotations target for win64 build since it is
          # a 32-bit library.
          'include_dirs': [
            '../..',
          ],
          'sources': [
            'modp_b64.cc',
            'modp_b64.h',
            'modp_b64_data.h',
          ],
          'configurations': {
            'Common_Base': {
              'msvs_target_platform': 'x64',
            },
          },
        },
      ],
    }],
  ],
}
