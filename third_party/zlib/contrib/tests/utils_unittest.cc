// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the Chromium source repository LICENSE file.

#include "infcover.h"

#include <cstddef>
#include <vector>

#include "compression_utils_portable.h"
#include "gtest.h"
#include "zlib.h"

void TestPayloads(size_t input_size, zlib_internal::WrapperType type) {
  std::vector<unsigned char> input;
  input.reserve(input_size);
  for (size_t i = 1; i <= input_size; ++i)
    input.push_back(i & 0xff);

  // If it is big enough for GZIP, will work for other wrappers.
  std::vector<unsigned char> compressed(
      zlib_internal::GzipExpectedCompressedSize(input.size()));
  std::vector<unsigned char> decompressed(input.size());

  // Libcores's java/util/zip/Deflater default settings: ZLIB,
  // DEFAULT_COMPRESSION and DEFAULT_STRATEGY.
  unsigned long compressed_size = static_cast<unsigned long>(compressed.size());
  int result = zlib_internal::CompressHelper(
      type, compressed.data(), &compressed_size, input.data(), input.size(),
      Z_DEFAULT_COMPRESSION, nullptr, nullptr);
  ASSERT_EQ(result, Z_OK);

  unsigned long decompressed_size =
      static_cast<unsigned long>(decompressed.size());
  result = zlib_internal::UncompressHelper(type, decompressed.data(),
                                           &decompressed_size,
                                           compressed.data(), compressed_size);
  ASSERT_EQ(result, Z_OK);
  EXPECT_EQ(input, decompressed);
}

TEST(ZlibTest, ZlibWrapper) {
  // Minimal ZLIB wrapped short stream size is about 8 bytes.
  for (size_t i = 1; i < 1024; ++i)
    TestPayloads(i, zlib_internal::WrapperType::ZLIB);
}

TEST(ZlibTest, GzipWrapper) {
  // GZIP should be 12 bytes bigger than ZLIB wrapper.
  for (size_t i = 1; i < 1024; ++i)
    TestPayloads(i, zlib_internal::WrapperType::GZIP);
}

TEST(ZlibTest, RawWrapper) {
  // RAW has no wrapper (V8 Blobs is a known user), size
  // should be payload_size + 2 for short payloads.
  for (size_t i = 1; i < 1024; ++i)
    TestPayloads(i, zlib_internal::WrapperType::ZRAW);
}

TEST(ZlibTest, InflateCover) {
  cover_support();
  cover_wrap();
  cover_back();
  cover_inflate();
  // TODO(cavalcantii): enable this last test.
  // cover_trees();
  cover_fast();
}

TEST(ZlibTest, DeflateStored) {
  const int no_compression = 0;
  const zlib_internal::WrapperType type = zlib_internal::WrapperType::GZIP;
  std::vector<unsigned char> input(1 << 10, 42);
  std::vector<unsigned char> compressed(
      zlib_internal::GzipExpectedCompressedSize(input.size()));
  std::vector<unsigned char> decompressed(input.size());
  unsigned long compressed_size = static_cast<unsigned long>(compressed.size());
  int result = zlib_internal::CompressHelper(
      type, compressed.data(), &compressed_size, input.data(), input.size(),
      no_compression, nullptr, nullptr);
  ASSERT_EQ(result, Z_OK);

  unsigned long decompressed_size =
      static_cast<unsigned long>(decompressed.size());
  result = zlib_internal::UncompressHelper(type, decompressed.data(),
                                           &decompressed_size,
                                           compressed.data(), compressed_size);
  ASSERT_EQ(result, Z_OK);
  EXPECT_EQ(input, decompressed);
}
