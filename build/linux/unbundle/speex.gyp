# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libspeex',
      'type': 'none',
      'variables': {
        'headers_root_path': 'include',
        'header_filenames': [
          'speex/speex_types.h',
          'speex/speex_callbacks.h',
          'speex/speex_config_types.h',
          'speex/speex_stereo.h',
          'speex/speex_echo.h',
          'speex/speex_preprocess.h',
          'speex/speex_jitter.h',
          'speex/speex.h',
          'speex/speex_resampler.h',
          'speex/speex_buffer.h',
          'speex/speex_header.h',
          'speex/speex_bits.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags speex)',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other speex)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l speex)',
        ],
      },
    },
  ],
}
