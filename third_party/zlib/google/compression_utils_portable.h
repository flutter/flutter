/* compression_utils_portable.h
 *
 * Copyright 2019 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the Chromium source repository LICENSE file.
 */
#ifndef THIRD_PARTY_ZLIB_GOOGLE_COMPRESSION_UTILS_PORTABLE_H_
#define THIRD_PARTY_ZLIB_GOOGLE_COMPRESSION_UTILS_PORTABLE_H_

#include <stdint.h>

#if defined(USE_SYSTEM_ZLIB)
#include <zlib.h>
#else
#include "third_party/zlib/zlib.h"
#endif

namespace zlib_internal {

enum WrapperType {
  ZLIB,
  GZIP,
  ZRAW,
};

uLongf GzipExpectedCompressedSize(uLongf input_size);

uint32_t GetGzipUncompressedSize(const Bytef* compressed_data, size_t length);

int GzipCompressHelper(Bytef* dest,
                       uLongf* dest_length,
                       const Bytef* source,
                       uLong source_length,
                       void* (*malloc_fn)(size_t),
                       void (*free_fn)(void*));

int CompressHelper(WrapperType wrapper_type,
                   Bytef* dest,
                   uLongf* dest_length,
                   const Bytef* source,
                   uLong source_length,
                   int compression_level,
                   void* (*malloc_fn)(size_t),
                   void (*free_fn)(void*));

int GzipUncompressHelper(Bytef* dest,
                         uLongf* dest_length,
                         const Bytef* source,
                         uLong source_length);

int UncompressHelper(WrapperType wrapper_type,
                     Bytef* dest,
                     uLongf* dest_length,
                     const Bytef* source,
                     uLong source_length);

}  // namespace zlib_internal

#endif  // THIRD_PARTY_ZLIB_GOOGLE_COMPRESSION_UTILS_PORTABLE_H_
