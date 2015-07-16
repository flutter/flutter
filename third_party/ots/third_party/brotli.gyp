# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'brotli',
      'type': 'static_library',
      'include_dirs': [
        'brotli/dec',
      ],
      'sources': [
        'brotli/dec/bit_reader.c',
        'brotli/dec/bit_reader.h',
        'brotli/dec/context.h',
        'brotli/dec/decode.c',
        'brotli/dec/decode.h',
        'brotli/dec/dictionary.h',
        'brotli/dec/huffman.c',
        'brotli/dec/huffman.h',
        'brotli/dec/prefix.h',
        'brotli/dec/safe_malloc.c',
        'brotli/dec/safe_malloc.h',
        'brotli/dec/streams.c',
        'brotli/dec/streams.h',
        'brotli/dec/transform.h',
        'brotli/dec/types.h',
      ],
    },
  ],
}
