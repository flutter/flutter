# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'memdump-unstripped',
      'type': 'executable',
      'dependencies': [
        '../../../base/base.gyp:base',
      ],
      'sources': [
        'memdump.cc',
      ],
    },
    {
      'target_name': 'memdump',
      'type': 'none',
      'dependencies': [
        'memdump-unstripped',
      ],
      'actions': [
        {
          'action_name': 'strip_memdump',
          'inputs': ['<(PRODUCT_DIR)/memdump-unstripped'],
          'outputs': ['<(PRODUCT_DIR)/memdump'],
          'action': [
            '<(android_strip)',
            '--strip-unneeded',
            '<@(_inputs)',
            '-o',
            '<@(_outputs)',
          ],
        },
      ],
    },
  ],
}
