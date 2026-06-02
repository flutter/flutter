// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_image_generator.h"

#include <cstdint>
#include <memory>
#include <optional>
#include <vector>

#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImageInfo.h"

namespace flutter {
namespace testing {

// Test seam: builds an AndroidImageGenerator with decoded pixel data injected
// directly, bypassing the JNI/NDK decode path (which cannot run on host) so the
// size guard in GetPixels can be exercised in isolation.
class AndroidImageGeneratorTest : public ::testing::Test {
 protected:
  static std::shared_ptr<AndroidImageGenerator> MakeWithDecodedData(
      const SkImageInfo& header_info,
      sk_sp<SkData> decoded_data) {
    std::shared_ptr<AndroidImageGenerator> generator(
        new AndroidImageGenerator(SkData::MakeEmpty()));
    generator->image_info_ = header_info;
    generator->software_decoded_data_ = std::move(decoded_data);
    // GetPixels() blocks on the latches before reading the decoded data.
    generator->header_decoded_latch_.Signal();
    generator->fully_decoded_latch_.Signal();
    return generator;
  }
};

// Regression test for the size guard added to GetPixels. When the decoded
// bitmap is larger than the header-derived destination buffer (as can happen on
// the HEIF/API 36 path, where the header dimensions and the decoded pixels come
// from independent decoders with no reconciliation), GetPixels must reject the
// copy rather than overflowing the destination. Under ASan an unguarded copy
// here would report a heap-buffer-overflow write.
TEST_F(AndroidImageGeneratorTest, GetPixelsRejectsOversizedDecodedData) {
  const SkImageInfo header_info =
      SkImageInfo::Make(64, 64, kRGBA_8888_SkColorType, kPremul_SkAlphaType);
  const size_t row_bytes = header_info.minRowBytes();
  const size_t dst_size = header_info.computeByteSize(row_bytes);
  std::vector<uint8_t> dst_pixels(dst_size, 0);

  // Decoded data sized as if the image were 256x256 instead of 64x64.
  const size_t oversized = static_cast<size_t>(256) * 256 * 4;
  ASSERT_GT(oversized, dst_size);
  auto generator =
      MakeWithDecodedData(header_info, SkData::MakeUninitialized(oversized));

  EXPECT_FALSE(generator->GetPixels(header_info, dst_pixels.data(), row_bytes,
                                    /*frame_index=*/0, std::nullopt));
}

// A well-formed image (decoded size == destination size) still copies
// successfully, i.e. the guard does not regress the normal path.
TEST_F(AndroidImageGeneratorTest, GetPixelsCopiesMatchingData) {
  const SkImageInfo info =
      SkImageInfo::Make(64, 64, kRGBA_8888_SkColorType, kPremul_SkAlphaType);
  const size_t row_bytes = info.minRowBytes();
  const size_t dst_size = info.computeByteSize(row_bytes);
  std::vector<uint8_t> dst_pixels(dst_size, 0);

  auto generator =
      MakeWithDecodedData(info, SkData::MakeUninitialized(dst_size));

  EXPECT_TRUE(generator->GetPixels(info, dst_pixels.data(), row_bytes,
                                   /*frame_index=*/0, std::nullopt));
}

}  // namespace testing
}  // namespace flutter
