# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 're2',
      'type': 'none',
      'variables': {
        'headers_root_path': '.',
        'header_filenames': [
          're2/filtered_re2.h',
          're2/re2.h',
          're2/set.h',
          're2/stringpiece.h',
          're2/variadic_function.h',
        ],
        'shim_generator_additional_args': [
          # Chromium copy of re2 is patched to rename POSIX to POSIX_SYNTAX
          # because of collision issues that break the build.
          # Upstream refuses to make changes:
          # http://code.google.com/p/re2/issues/detail?id=73 .
          '--define', 'POSIX=POSIX_SYNTAX',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'link_settings': {
        'libraries': [
          '-lre2',
        ],
      },
    }
  ],
}
