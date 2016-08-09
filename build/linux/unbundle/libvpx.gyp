# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'targets': [
    {
      'target_name': 'libvpx',
      'type': 'none',
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags vpx)',
        ],
      },
      'variables': {
        'headers_root_path': 'source/libvpx',
        'header_filenames': [
          'vpx/vp8.h',
          'vpx/vp8cx.h',
          'vpx/vp8dx.h',
          'vpx/vpx_codec.h',
          'vpx/vpx_codec_impl_bottom.h',
          'vpx/vpx_codec_impl_top.h',
          'vpx/vpx_decoder.h',
          'vpx/vpx_encoder.h',
          'vpx/vpx_frame_buffer.h',
          'vpx/vpx_image.h',
          'vpx/vpx_integer.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other vpx)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l vpx)',
        ],
      },
    },
  ],
}
