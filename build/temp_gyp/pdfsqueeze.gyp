# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'pdfsqueeze',
      'type': 'executable',
      'sources': [
        '../../third_party/pdfsqueeze/pdfsqueeze.m',
      ],
      'defines': [
        # Use defines to map the full path names that will be used for
        # the vars into the short forms expected by pdfsqueeze.m.
        '______third_party_pdfsqueeze_ApplyGenericRGB_qfilter=ApplyGenericRGB_qfilter',
        '______third_party_pdfsqueeze_ApplyGenericRGB_qfilter_len=ApplyGenericRGB_qfilter_len',
      ],
      'include_dirs': [
        '<(INTERMEDIATE_DIR)',
      ],
      'libraries': [
        '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
        '$(SDKROOT)/System/Library/Frameworks/Quartz.framework',
      ],
      'actions': [
        {
          'action_name': 'Generate inline filter data',
          'inputs': [
            '../../third_party/pdfsqueeze/ApplyGenericRGB.qfilter',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/ApplyGenericRGB.h',
          ],
          'action': ['xxd', '-i', '<@(_inputs)', '<@(_outputs)'],
        },
      ],
    },
  ],
}
