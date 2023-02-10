// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_color_source.h"
#include "flutter/display_list/testing/dl_test_equality.h"
#include "flutter/display_list/types.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

static void arraysEqual(const uint32_t* ints,
                        const DlColor* colors,
                        int count) {
  for (int i = 0; i < count; i++) {
    EXPECT_TRUE(ints[i] == colors[i]);
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

}  // namespace testing
}  // namespace flutter
