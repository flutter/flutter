# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libXNVCtrl',
      'type': 'static_library',
      'sources': [
        'NVCtrl.c',
        'NVCtrl.h',
        'NVCtrlLib.h',
        'nv_control.h',
      ],
    },
  ],
}
