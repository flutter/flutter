# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'run_pie-unstripped',
      'type': 'executable',
      'sources': [
        'run_pie.c',
      ],
      # See crbug.com/373219. This is the only Android executable which must be
      # non PIE.
      'cflags!': [
        '-fPIE',
      ],
      'ldflags!': [
        '-pie',
      ],
      # Don't inherit unneeded dependencies on libc++, so the binary remains
      # self-contained also in component=shared_library builds.
      'libraries!': [
        '-l<(android_libcpp_library)',
      ],
    },
    {
      'target_name': 'run_pie',
      'type': 'none',
      'dependencies': [
        'run_pie-unstripped',
      ],
      'actions': [
        {
          'action_name': 'strip_run_pie',
          'inputs': ['<(PRODUCT_DIR)/run_pie-unstripped'],
          'outputs': ['<(PRODUCT_DIR)/run_pie'],
          'action': [
            '<(android_strip)',
            '--strip-unneeded',
            '<@(_inputs)',
            '-o',
            '<@(_outputs)',
          ],
        },
      ],
    },
  ],
}
