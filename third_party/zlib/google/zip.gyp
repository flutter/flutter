# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'zip',
      'type': 'static_library',
      'dependencies': [
        '../zlib.gyp:minizip',
        '../../../base/base.gyp:base',
      ],
      'include_dirs': [
        '../../..',
      ],
      'sources': [
        'zip.cc',
        'zip.h',
        'zip_internal.cc',
        'zip_internal.h',
        'zip_reader.cc',
        'zip_reader.h',
      ],
    },
  ],
}
