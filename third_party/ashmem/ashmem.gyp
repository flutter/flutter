# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'ashmem',
      'type': 'static_library',
      'sources': [
        'ashmem.h',
        'ashmem-dev.c'
      ],
    },
  ],
}
