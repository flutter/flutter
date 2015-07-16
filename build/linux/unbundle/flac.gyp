# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'libflac',
      'type': 'none',
      'variables': {
        'headers_root_path': 'include',
        'header_filenames': [
          'FLAC/callback.h',
          'FLAC/metadata.h',
          'FLAC/assert.h',
          'FLAC/export.h',
          'FLAC/format.h',
          'FLAC/stream_decoder.h',
          'FLAC/stream_encoder.h',
          'FLAC/ordinals.h',
          'FLAC/all.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other flac)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l flac)',
        ],
      },
    },
  ],
}
