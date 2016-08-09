# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'jsoncpp',
      'type': 'none',
      'variables': {
        'headers_root_path': 'source/include',
        'header_filenames': [
          'json/assertions.h',
          'json/autolink.h',
          'json/config.h',
          'json/features.h',
          'json/forwards.h',
          'json/json.h',
          'json/reader.h',
          'json/value.h',
          'json/writer.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '/usr/include/jsoncpp',
        ],
      },
      'link_settings': {
        'libraries': [
          '-ljsoncpp',
        ],
      },
    }
  ],
}
