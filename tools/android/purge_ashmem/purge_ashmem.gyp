# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'purge_ashmem',
      'type': 'executable',
      'dependencies': [
        '../../../third_party/ashmem/ashmem.gyp:ashmem',
      ],
      'include_dirs': [
        '../../../',
      ],
      'sources': [
        'purge_ashmem.c',
      ],
    },
  ],
}
