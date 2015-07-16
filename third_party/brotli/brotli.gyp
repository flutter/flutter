# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'brotli',
      'type': 'static_library',
      'include_dirs': [
        'dec',
      ],
      'sources': [
        'dec/bit_reader.c',
        'dec/bit_reader.h',
        'dec/context.h',
        'dec/decode.c',
        'dec/decode.h',
        'dec/dictionary.h',
        'dec/huffman.c',
        'dec/huffman.h',
        'dec/prefix.h',
        'dec/safe_malloc.c',
        'dec/safe_malloc.h',
        'dec/streams.c',
        'dec/streams.h',
        'dec/transform.h',
        'dec/types.h',
      ],
    },
  ],
}
