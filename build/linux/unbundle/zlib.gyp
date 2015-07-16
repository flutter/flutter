# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'zlib',
      'type': 'none',
      'variables': {
        'headers_root_path': '.',
        'header_filenames': [
          'zlib.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'direct_dependent_settings': {
        'defines': [
          'USE_SYSTEM_ZLIB',
        ],
      },
      'link_settings': {
        'libraries': [
          '-lz',
        ],
      },
    },
    {
      'target_name': 'minizip',
      'type': 'static_library',
      'all_dependent_settings': {
        'defines': [
          'USE_SYSTEM_MINIZIP',
        ],
      },
      'defines': [
        'USE_SYSTEM_MINIZIP',
      ],
      'link_settings': {
        'libraries': [
          '-lminizip',
        ],
      },
    },
    {
      'target_name': 'zip',
      'type': 'static_library',
      'dependencies': [
        'minizip',
        '../../base/base.gyp:base',
      ],
      'include_dirs': [
        '../..',
      ],
      'sources': [
        'google/zip.cc',
        'google/zip.h',
        'google/zip_internal.cc',
        'google/zip_internal.h',
        'google/zip_reader.cc',
        'google/zip_reader.h',
      ],
    },
  ],
}
