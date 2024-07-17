// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_color.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkColor.h"

namespace flutter {
namespace testing {

static void arraysEqual(const uint32_t* ints,
                        const DlColor* colors,
                        int count) {
  for (int i = 0; i < count; i++) {
    EXPECT_TRUE(ints[i] == colors[i].argb());
  }
}

TEST(DisplayListColor, ArrayInterchangeableWithUint32) {
  uint32_t ints[5] = {
      0xFF000000,  //
      0xFFFF0000,  //
      0xFF00FF00,  //
      0xFF0000FF,  //
      0xF1F2F3F4,
  };
  DlColor colors[5] = {
      DlColor::kBlack(),  //
      DlColor::kRed(),    //
      DlColor::kGreen(),  //
      DlColor::kBlue(),   //
      DlColor(0xF1F2F3F4),
  };
  arraysEqual(ints, colors, 5);
  arraysEqual(reinterpret_cast<const uint32_t*>(colors),
              reinterpret_cast<const DlColor*>(ints), 5);
}

TEST(DisplayListColor, DlColorDirectlyComparesToSkColor) {
  EXPECT_EQ(DlColor::kBlack(), SK_ColorBLACK);
  EXPECT_EQ(DlColor::kRed(), SK_ColorRED);
  EXPECT_EQ(DlColor::kGreen(), SK_ColorGREEN);
  EXPECT_EQ(DlColor::kBlue(), SK_ColorBLUE);
}

TEST(DisplayListColor, DlColorFloatConstructor) {
  EXPECT_EQ(DlColor::ARGB(1.0f, 1.0f, 1.0f, 1.0f), DlColor(0xFFFFFFFF));
  EXPECT_EQ(DlColor::ARGB(0.0f, 0.0f, 0.0f, 0.0f), DlColor(0x00000000));
  EXPECT_EQ(DlColor::ARGB(0.5f, 0.5f, 0.5f, 0.5f), DlColor(0x80808080));
  EXPECT_EQ(DlColor::ARGB(1.0f, 0.0f, 0.5f, 1.0f), DlColor(0xFF0080FF));

  EXPECT_EQ(DlColor::RGBA(1.0f, 1.0f, 1.0f, 1.0f), DlColor(0xFFFFFFFF));
  EXPECT_EQ(DlColor::RGBA(0.0f, 0.0f, 0.0f, 0.0f), DlColor(0x00000000));
  EXPECT_EQ(DlColor::RGBA(0.5f, 0.5f, 0.5f, 0.5f), DlColor(0x80808080));
  EXPECT_EQ(DlColor::RGBA(1.0f, 0.0f, 0.5f, 1.0f), DlColor(0xFFFF0080));
}

TEST(DisplayListColor, DlColorComponentGetters) {
  {
    DlColor test(0xFFFFFFFF);

    EXPECT_EQ(test.getAlpha(), 0xFF);
    EXPECT_EQ(test.getRed(), 0xFF);
    EXPECT_EQ(test.getGreen(), 0xFF);
    EXPECT_EQ(test.getBlue(), 0xFF);

    EXPECT_EQ(test.getAlphaF(), 1.0f);
    EXPECT_EQ(test.getRedF(), 1.0f);
    EXPECT_EQ(test.getGreenF(), 1.0f);
    EXPECT_EQ(test.getBlueF(), 1.0f);
  }

  {
    DlColor test = DlColor::ARGB(1.0f, 1.0f, 1.0f, 1.0f);

    EXPECT_EQ(test.getAlpha(), 0xFF);
    EXPECT_EQ(test.getRed(), 0xFF);
    EXPECT_EQ(test.getGreen(), 0xFF);
    EXPECT_EQ(test.getBlue(), 0xFF);

    EXPECT_EQ(test.getAlphaF(), 1.0f);
    EXPECT_EQ(test.getRedF(), 1.0f);
    EXPECT_EQ(test.getGreenF(), 1.0f);
    EXPECT_EQ(test.getBlueF(), 1.0f);
  }

  {
    DlColor test(0x00000000);

    EXPECT_EQ(test.getAlpha(), 0x00);
    EXPECT_EQ(test.getRed(), 0x00);
    EXPECT_EQ(test.getGreen(), 0x00);
    EXPECT_EQ(test.getBlue(), 0x00);

    EXPECT_EQ(test.getAlphaF(), 0.0f);
    EXPECT_EQ(test.getRedF(), 0.0f);
    EXPECT_EQ(test.getGreenF(), 0.0f);
    EXPECT_EQ(test.getBlueF(), 0.0f);
  }

  {
    DlColor test = DlColor::ARGB(0.0f, 0.0f, 0.0f, 0.0f);

    EXPECT_EQ(test.getAlpha(), 0x00);
    EXPECT_EQ(test.getRed(), 0x00);
    EXPECT_EQ(test.getGreen(), 0x00);
    EXPECT_EQ(test.getBlue(), 0x00);

    EXPECT_EQ(test.getAlphaF(), 0.0f);
    EXPECT_EQ(test.getRedF(), 0.0f);
    EXPECT_EQ(test.getGreenF(), 0.0f);
    EXPECT_EQ(test.getBlueF(), 0.0f);
  }

  {
    DlColor test(0x7F7F7F7F);

    EXPECT_EQ(test.getAlpha(), 0x7F);
    EXPECT_EQ(test.getRed(), 0x7F);
    EXPECT_EQ(test.getGreen(), 0x7F);
    EXPECT_EQ(test.getBlue(), 0x7F);

    const DlScalar half = 127.0f * (1.0f / 255.0f);

    EXPECT_EQ(test.getAlphaF(), half);
    EXPECT_EQ(test.getRedF(), half);
    EXPECT_EQ(test.getGreenF(), half);
    EXPECT_EQ(test.getBlueF(), half);
  }

  {
    DlColor test = DlColor::ARGB(0.5f, 0.5f, 0.5f, 0.5f);

    EXPECT_EQ(test.getAlpha(), 0x80);
    EXPECT_EQ(test.getRed(), 0x80);
    EXPECT_EQ(test.getGreen(), 0x80);
    EXPECT_EQ(test.getBlue(), 0x80);

    const DlScalar half = 128.0f * (1.0f / 255.0f);

    EXPECT_EQ(test.getAlphaF(), half);
    EXPECT_EQ(test.getRedF(), half);
    EXPECT_EQ(test.getGreenF(), half);
    EXPECT_EQ(test.getBlueF(), half);
  }

  {
    DlColor test(0x1F2F3F4F);

    EXPECT_EQ(test.getAlpha(), 0x1F);
    EXPECT_EQ(test.getRed(), 0x2F);
    EXPECT_EQ(test.getGreen(), 0x3F);
    EXPECT_EQ(test.getBlue(), 0x4F);

    EXPECT_EQ(test.getAlphaF(), 0x1f * (1.0f / 255.0f));
    EXPECT_EQ(test.getRedF(), 0x2f * (1.0f / 255.0f));
    EXPECT_EQ(test.getGreenF(), 0x3f * (1.0f / 255.0f));
    EXPECT_EQ(test.getBlueF(), 0x4f * (1.0f / 255.0f));
  }

  {
    DlColor test = DlColor::ARGB(0.1f, 0.2f, 0.3f, 0.4f);

    EXPECT_EQ(test.getAlpha(), round(0.1f * 255));
    EXPECT_EQ(test.getRed(), round(0.2f * 255));
    EXPECT_EQ(test.getGreen(), round(0.3f * 255));
    EXPECT_EQ(test.getBlue(), round(0.4f * 255));

    // Unfortunately conversion from float to 8-bit back to float is lossy
    EXPECT_EQ(test.getAlphaF(), round(0.1f * 255) * (1.0f / 255.0f));
    EXPECT_EQ(test.getRedF(), round(0.2f * 255) * (1.0f / 255.0f));
    EXPECT_EQ(test.getGreenF(), round(0.3f * 255) * (1.0f / 255.0f));
    EXPECT_EQ(test.getBlueF(), round(0.4f * 255) * (1.0f / 255.0f));
  }

  {
    DlColor test = DlColor::RGBA(0.2f, 0.3f, 0.4f, 0.1f);

    EXPECT_EQ(test.getAlpha(), round(0.1f * 255));
    EXPECT_EQ(test.getRed(), round(0.2f * 255));
    EXPECT_EQ(test.getGreen(), round(0.3f * 255));
    EXPECT_EQ(test.getBlue(), round(0.4f * 255));

    // Unfortunately conversion from float to 8-bit back to float is lossy
    EXPECT_EQ(test.getAlphaF(), round(0.1f * 255) * (1.0f / 255.0f));
    EXPECT_EQ(test.getRedF(), round(0.2f * 255) * (1.0f / 255.0f));
    EXPECT_EQ(test.getGreenF(), round(0.3f * 255) * (1.0f / 255.0f));
    EXPECT_EQ(test.getBlueF(), round(0.4f * 255) * (1.0f / 255.0f));
  }
}

TEST(DisplayListColor, DlColorOpaqueTransparent) {
  auto test_argb = [](int a, int r, int g, int b) {
    ASSERT_TRUE(a >= 0 && a <= 255);
    ASSERT_TRUE(r >= 0 && r <= 255);
    ASSERT_TRUE(g >= 0 && g <= 255);
    ASSERT_TRUE(b >= 0 && b <= 255);

    int argb = ((a << 24) | (r << 16) | (g << 8) | b);
    bool is_opaque = (a == 255);
    bool is_transprent = (a == 0);

    EXPECT_EQ(DlColor(argb).isOpaque(), is_opaque);
    EXPECT_EQ(DlColor(argb).isTransparent(), is_transprent);

    DlScalar aF = a * (1.0f / 255.0f);
    DlScalar rF = r * (1.0f / 255.0f);
    DlScalar gF = g * (1.0f / 255.0f);
    DlScalar bF = b * (1.0f / 255.0f);

    EXPECT_EQ(DlColor::ARGB(aF, rF, gF, bF).isOpaque(), is_opaque);
    EXPECT_EQ(DlColor::ARGB(aF, rF, gF, bF).isTransparent(), is_transprent);

    EXPECT_EQ(DlColor::RGBA(rF, gF, bF, aF).isOpaque(), is_opaque);
    EXPECT_EQ(DlColor::RGBA(rF, gF, bF, aF).isTransparent(), is_transprent);
  };

  for (int r = 0; r <= 255; r += 15) {
    for (int g = 0; g <= 255; g += 15) {
      for (int b = 0; b <= 255; b += 15) {
        test_argb(0, r, g, b);
        for (int a = 15; a < 255; a += 15) {
          test_argb(a, r, g, b);
        }
        test_argb(255, r, g, b);
      }
    }
  }
}

}  // namespace testing
}  // namespace flutter
