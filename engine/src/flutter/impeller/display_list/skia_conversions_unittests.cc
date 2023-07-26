// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/display_list/skia_conversions.h"
#include "impeller/geometry/scalar.h"

namespace impeller {
namespace testing {

TEST(SkiaConversionsTest, ToColor) {
  // Create a color with alpha, red, green, and blue values that are all
  // trivially divisible by 255 so that we can test the conversion results in
  // correct scalar values.
  //                               AARRGGBB
  const flutter::DlColor color = 0x8040C020;
  auto converted_color = skia_conversions::ToColor(color);

  ASSERT_TRUE(ScalarNearlyEqual(converted_color.alpha, 0x80 * (1.0f / 255)));
  ASSERT_TRUE(ScalarNearlyEqual(converted_color.red, 0x40 * (1.0f / 255)));
  ASSERT_TRUE(ScalarNearlyEqual(converted_color.green, 0xC0 * (1.0f / 255)));
  ASSERT_TRUE(ScalarNearlyEqual(converted_color.blue, 0x20 * (1.0f / 255)));
}

}  // namespace testing
}  // namespace impeller
