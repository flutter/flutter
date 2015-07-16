# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'forwarder',
      'type': 'none',
      'dependencies': [
        'forwarder_symbols',
      ],
      'actions': [
        {
          'action_name': 'strip_forwarder',
          'inputs': ['<(PRODUCT_DIR)/forwarder_symbols'],
          'outputs': ['<(PRODUCT_DIR)/forwarder'],
          'action': [
            '<(android_strip)',
            '--strip-unneeded',
            '<@(_inputs)',
            '-o',
            '<@(_outputs)',
          ],
        },
      ],
    }, {
      'target_name': 'forwarder_symbols',
      'type': 'executable',
      'dependencies': [
        '../../../base/base.gyp:base',
        '../common/common.gyp:android_tools_common',
      ],
      'include_dirs': [
        '../../..',
      ],
      'sources': [
        'forwarder.cc',
      ],
    },
  ],
}

