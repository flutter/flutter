# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'ps_ext-unstripped',
      'type': 'executable',
      'sources': [
        'ps_ext.c',
      ],
    },
    {
      'target_name': 'ps_ext',
      'type': 'none',
      'dependencies': [
        'ps_ext-unstripped',
      ],
      'actions': [
        {
          'action_name': 'strip_ps_ext',
          'inputs': ['<(PRODUCT_DIR)/ps_ext-unstripped'],
          'outputs': ['<(PRODUCT_DIR)/ps_ext'],
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
