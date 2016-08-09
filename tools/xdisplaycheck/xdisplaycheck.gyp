# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN version: //tools/xdisplaycheck
      'target_name': 'xdisplaycheck',
      'type': 'executable',
      'dependencies': [
        '../../build/linux/system.gyp:x11',
      ],
      'sources': [
        'xdisplaycheck.cc',
      ],
    },
  ],
}
