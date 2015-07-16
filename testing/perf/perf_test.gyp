# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'perf_test',
      'type': 'static_library',
      'sources': [
        'perf_test.cc',
      ],
      'dependencies': [
        '../../base/base.gyp:base',
      ],
    },
  ],
}
