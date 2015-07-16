# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'dynamic_annotations',
      'type': 'static_library',
      'toolsets': ['host', 'target'],
      'include_dirs': [
        '../../../',
      ],
      'sources': [
        '../valgrind/valgrind.h',
        'dynamic_annotations.c',
        'dynamic_annotations.h',
      ],
      'includes': [
        '../../../build/android/increase_size_for_speed.gypi',
      ],
    },
  ],
  'conditions': [
    ['OS == "win" and target_arch=="ia32"', {
      'targets': [
        {
          'target_name': 'dynamic_annotations_win64',
          'type': 'static_library',
          # We can't use dynamic_annotations target for win64 build since it is
          # a 32-bit library.
          # TODO(gregoryd): merge with dynamic_annotations when
          # the win32/64 targets are merged.
          'include_dirs': [
              '../../../',
          ],
          'sources': [
            'dynamic_annotations.c',
            'dynamic_annotations.h',
          ],
          'configurations': {
            'Common_Base': {
              'msvs_target_platform': 'x64',
            },
          },
        },
      ],
    }],
  ],
}
