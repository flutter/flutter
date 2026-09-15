// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_image_generator.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(AndroidImageGenerator, HeaderDecodeDimensionMismatch) {
  constexpr int kHeaderW = 2;
  constexpr int kHeaderH = 2;
  SkImageInfo header_info = SkImageInfo::Make(
      kHeaderW, kHeaderH, kRGBA_8888_SkColorType, kPremul_SkAlphaType);

  constexpr int kDecodedW = 64;
  constexpr int kDecodedH = 64;
  sk_sp<SkData> decoded =
      SkData::MakeZeroInitialized(kDecodedW * kDecodedH * sizeof(uint32_t));

  // Create an AndroidImageGenerator where the dimensions in the header
  // ImageInfo do not match the dimensions of the decoded data.
  auto gen =
      AndroidImageGenerator::MakeForTesting(header_info, std::move(decoded));

  ASSERT_EQ(gen->GetInfo().dimensions(), SkISize(kHeaderW, kHeaderH));

  // AndroidImageGenerator should detect that the buffer size derived from the
  // SkImageInfo is insufficent for the decoded data.
  sk_sp<SkImage> image = gen->GetImage();
  EXPECT_EQ(image, nullptr);
}

}  // namespace testing
}  // namespace flutter
