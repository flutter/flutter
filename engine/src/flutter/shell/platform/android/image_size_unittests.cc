// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/android/image_size.h"
#include "gtest/gtest.h"
namespace flutter {
namespace testing {
TEST(ImageSizeTest, ExcludesRightAndBottomAllocationPadding) {
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(322, 322), 336, 336),
            SkRect::MakeWH(322.f / 336, 322.f / 336));
}
TEST(ImageSizeTest, ExcludesSoftwareDecoderAllocationPadding) {
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(720, 1280), 768, 1280),
            SkRect::MakeWH(720.f / 768, 1));
}
TEST(ImageSizeTest, DoesNotApplyRotation) {
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(1280, 720), 1280, 768),
            SkRect::MakeWH(1, 720.f / 768));
}
TEST(ImageSizeTest, FullAllocationIsUnchanged) {
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(320, 320), 320, 320),
            SkRect::MakeWH(1, 1));
}
TEST(ImageSizeTest, InvalidDimensionsDoNotClipContent) {
  const auto full = SkRect::MakeWH(1, 1);
  EXPECT_EQ(NormalizeImageBounds(std::nullopt, 336, 336), full);
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(0, 322), 336, 336), full);
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(-1, 322), 336, 336), full);
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(337, 322), 336, 336), full);
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(322, 337), 336, 336), full);
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(322, 322), 0, 336), full);
  EXPECT_EQ(NormalizeImageBounds(SkISize::Make(322, 322), 336, 0), full);
}
}  // namespace testing
}  // namespace flutter
