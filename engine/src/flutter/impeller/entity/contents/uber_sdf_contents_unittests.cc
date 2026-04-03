// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/entity/contents/filled_rect_sdf_contents.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/rect.h"

namespace impeller {
namespace testing {

TEST(UberSDFContentsTest, ApplyColorFilter) {
  auto rect = Rect::MakeXYWH(100, 100, 200, 200);
  auto geometry = std::make_unique<FillRectGeometry>(rect);
  auto contents = UberSDFContents<FillRectGeometry>::Make(Color::Red(),
                                                           std::move(geometry));
  ASSERT_EQ(contents->GetColor(), Color::Red());

  bool result =
      contents->ApplyColorFilter([](Color color) { return Color::Blue(); });

  ASSERT_TRUE(result);
  ASSERT_EQ(contents->GetColor(), Color::Blue());
}

}  // namespace testing
}  // namespace impeller
