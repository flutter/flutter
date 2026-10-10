// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_image_generator.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(AndroidImageGenerator, HeaderDecodeDimensionMismatch) {
  constexpr uint32_t kHeaderW = 2;
  constexpr uint32_t kHeaderH = 2;
  FlutterImageGeneratorInfo header_info = {
      .width = kHeaderW,
      .height = kHeaderH,
      .color_type = kFlutterImageGeneratorColorTypeRGBA8888,
      .alpha_type = kFlutterImageGeneratorAlphaTypePremul,
  };

  constexpr size_t kDecodedW = 64;
  constexpr size_t kDecodedH = 64;
  std::vector<uint8_t> decoded(kDecodedW * kDecodedH * sizeof(uint32_t), 0);

  // Create an AndroidImageGenerator where the dimensions in the header
  // ImageInfo do not match the dimensions of the decoded data.
  auto gen =
      AndroidImageGenerator::MakeForTesting(header_info, std::move(decoded));

  ASSERT_EQ(gen->GetInfo().width, kHeaderW);
  ASSERT_EQ(gen->GetInfo().height, kHeaderH);

  // AndroidImageGenerator should detect that the buffer size derived from the
  // header FlutterImageGeneratorInfo is insufficient for the decoded data.
  constexpr size_t kHeaderRowBytes = kHeaderW * sizeof(uint32_t);
  std::vector<uint8_t> output_pixels(kHeaderRowBytes * kHeaderH, 0);
  EXPECT_FALSE(
      gen->GetPixels(gen->GetInfo(), output_pixels.data(), kHeaderRowBytes));
}

}  // namespace testing
}  // namespace flutter
