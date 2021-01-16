// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/zlib/google/compression_utils.h"

#include <stddef.h>
#include <stdint.h>

#include <string>

#include "base/stl_util.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace compression {

namespace {

// The data to be compressed by gzip. This is the hex representation of "hello
// world".
const uint8_t kData[] = {0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20,
                         0x77, 0x6f, 0x72, 0x6c, 0x64};

// This is the string representation of gzip compressed string above. It was
// obtained by running echo -n "hello world" | gzip -c | hexdump -e '8 1 ",
// 0x%x"' followed by 0'ing out the OS byte (10th byte) in the header. This is
// so that the test passes on all platforms (that run various OS'es).
const uint8_t kCompressedData[] = {
    0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcb,
    0x48, 0xcd, 0xc9, 0xc9, 0x57, 0x28, 0xcf, 0x2f, 0xca, 0x49, 0x01,
    0x00, 0x85, 0x11, 0x4a, 0x0d, 0x0b, 0x00, 0x00, 0x00};

}  // namespace

TEST(CompressionUtilsTest, GzipCompression) {
  std::string data(reinterpret_cast<const char*>(kData), base::size(kData));
  std::string compressed_data;
  EXPECT_TRUE(GzipCompress(data, &compressed_data));
  std::string golden_compressed_data(
      reinterpret_cast<const char*>(kCompressedData),
      base::size(kCompressedData));
  EXPECT_EQ(golden_compressed_data, compressed_data);
}

TEST(CompressionUtilsTest, GzipUncompression) {
  std::string compressed_data(reinterpret_cast<const char*>(kCompressedData),
                              base::size(kCompressedData));

  std::string uncompressed_data;
  EXPECT_TRUE(GzipUncompress(compressed_data, &uncompressed_data));

  std::string golden_data(reinterpret_cast<const char*>(kData),
                          base::size(kData));
  EXPECT_EQ(golden_data, uncompressed_data);
}

TEST(CompressionUtilsTest, GzipUncompressionFromSpanToString) {
  std::string uncompressed_data;
  EXPECT_TRUE(GzipUncompress(kCompressedData, &uncompressed_data));

  std::string golden_data(reinterpret_cast<const char*>(kData),
                          base::size(kData));
  EXPECT_EQ(golden_data, uncompressed_data);
}

// Checks that compressing/decompressing input > 256 bytes works as expected.
TEST(CompressionUtilsTest, LargeInput) {
  const size_t kSize = 32 * 1024;

  // Generate a data string of |kSize| for testing.
  std::string data;
  data.resize(kSize);
  for (size_t i = 0; i < kSize; ++i)
    data[i] = static_cast<char>(i & 0xFF);

  std::string compressed_data;
  EXPECT_TRUE(GzipCompress(data, &compressed_data));

  std::string uncompressed_data;
  EXPECT_TRUE(GzipUncompress(compressed_data, &uncompressed_data));

  EXPECT_EQ(data, uncompressed_data);
}

TEST(CompressionUtilsTest, InPlace) {
  const std::string original_data(reinterpret_cast<const char*>(kData),
                                  base::size(kData));
  const std::string golden_compressed_data(
      reinterpret_cast<const char*>(kCompressedData),
      base::size(kCompressedData));

  std::string data(original_data);
  EXPECT_TRUE(GzipCompress(data, &data));
  EXPECT_EQ(golden_compressed_data, data);
  EXPECT_TRUE(GzipUncompress(data, &data));
  EXPECT_EQ(original_data, data);
}

}  // namespace compression
