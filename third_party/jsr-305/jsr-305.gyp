# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'jsr_305_javalib',
      'type': 'none',
      'variables': {
        # The sources are not located in a folder that is called src/, so we
        # need to set it in additional_src_dirs parameter instead.
        'java_in_dir': '../../build/android/empty',
        'additional_src_dirs': [ 'src/ri/' ],
      },
      'includes': [ '../../build/java.gypi' ],
    },
  ]
}
