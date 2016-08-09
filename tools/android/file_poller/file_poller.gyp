# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'file_poller',
      'type': 'executable',
      'dependencies': [
        '../../../base/base.gyp:base',
      ],
      'sources': [
        'file_poller.cc',
      ],
    },
  ],
}
