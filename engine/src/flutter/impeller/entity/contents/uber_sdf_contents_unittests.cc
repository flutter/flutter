// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/entity/contents/uber_sdf_contents.h"
<<<<<<< HEAD
#include "impeller/entity/geometry/rect_geometry.h"
=======
#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/entity/geometry/uber_sdf_geometry.h"
>>>>>>> 49233d08009 (Reverts "Disable async mode with LLDB (#184768)" (#184868))
#include "impeller/geometry/rect.h"

namespace impeller {
namespace testing {

TEST(UberSDFContentsTest, ApplyColorFilter) {
  auto rect = Rect::MakeXYWH(100, 100, 200, 200);
<<<<<<< HEAD
  FillRectGeometry geometry(rect);
  auto contents = UberSDFContents::MakeRect(Color::Red(), 0.0f, Join::kMiter,
                                            false, &geometry);
=======
  auto params =
      UberSDFParameters::MakeRect(Color::Red(), rect, /*stroke=*/std::nullopt);
  auto geometry = std::make_unique<UberSDFGeometry>(params);
  auto contents = UberSDFContents::Make(params, std::move(geometry));
>>>>>>> 49233d08009 (Reverts "Disable async mode with LLDB (#184768)" (#184868))

  ASSERT_EQ(contents->GetColor(), Color::Red());

  bool result =
      contents->ApplyColorFilter([](Color color) { return Color::Blue(); });

  ASSERT_TRUE(result);
  ASSERT_EQ(contents->GetColor(), Color::Blue());
}

}  // namespace testing
}  // namespace impeller
