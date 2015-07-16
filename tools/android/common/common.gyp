# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'targets': [
    {
      # GN version: //tools/android/common
      'target_name': 'android_tools_common',
      'type': 'static_library',
      'toolsets': ['host', 'target'],
      'include_dirs': [
        '..',
        '../../..',
      ],
      'sources': [
        'adb_connection.cc',
        'adb_connection.h',
        'daemon.cc',
        'daemon.h',
        'net.cc',
        'net.h',
      ],
    },
  ],
}

