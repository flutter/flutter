// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_ZLIB_GOOGLE_COMPRESSION_UTILS_H_
#define THIRD_PARTY_ZLIB_GOOGLE_COMPRESSION_UTILS_H_

#include <string>

#include "base/containers/span.h"

namespace compression {

// Compresses the data in |input| using gzip, storing the result in
// |output_buffer|, of size |output_buffer_size|. If the buffer is large enough
// and compression succeeds, |compressed_size| points to the compressed data
// size after the call.
// |malloc_fn| and |free_fn| are pointers to malloc() and free()-like functions,
// or nullptr to use the standard ones.
// Returns true for success.
bool GzipCompress(base::span<const char> input,
                  char* output_buffer,
                  size_t output_buffer_size,
                  size_t* compressed_size,
                  void* (*malloc_fn)(size_t),
                  void (*free_fn)(void*));

// Compresses the data in |input| using gzip, storing the result in |output|.
// |input| and |output| are allowed to point to the same string (in-place
// operation).
// Returns true for success.
bool GzipCompress(base::span<const char> input, std::string* output);

// Like the above method, but using uint8_t instead.
bool GzipCompress(base::span<const uint8_t> input, std::string* output);

// Uncompresses the data in |input| using gzip, storing the result in |output|.
// |input| and |output| are allowed to be the same string (in-place operation).
// Returns true for success.
bool GzipUncompress(const std::string& input, std::string* output);

// Like the above method, but uses base::span to avoid allocations if
// needed. |output|'s size must be at least as large as the return value from
// GetUncompressedSize.
// Returns true for success.
bool GzipUncompress(base::span<const char> input,
                    base::span<const char> output);

// Like the above method, but using uint8_t instead.
bool GzipUncompress(base::span<const uint8_t> input,
                    base::span<const uint8_t> output);

// Uncompresses the data in |input| using gzip, and writes the results to
// |output|, which must NOT be the underlying string of |input|, and is resized
// if necessary.
// Returns true for success.
bool GzipUncompress(base::span<const char> input, std::string* output);

// Like the above method, but using uint8_t instead.
bool GzipUncompress(base::span<const uint8_t> input, std::string* output);

// Returns the uncompressed size from GZIP-compressed |compressed_data|.
uint32_t GetUncompressedSize(base::span<const char> compressed_data);

// Like the above method, but using uint8_t instead.
uint32_t GetUncompressedSize(base::span<const uint8_t> compressed_data);

}  // namespace compression

#endif  // THIRD_PARTY_ZLIB_GOOGLE_COMPRESSION_UTILS_H_
