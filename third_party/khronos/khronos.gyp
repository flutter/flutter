# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'khronos_headers',
      'type': 'none',
      'all_dependent_settings': {
        'include_dirs': [
          '.',
          '../../gpu',  # Contains GLES2/gl2chromium.h
        ],
      },
    },
  ],
}
