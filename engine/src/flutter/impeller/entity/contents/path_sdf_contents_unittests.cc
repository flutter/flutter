// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/entity/contents/path_sdf_contents.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {
namespace testing {

TEST(PathSdfContentsTest, SimpleMake) {
  flutter::DlPath path = flutter::DlPath::MakeRect(Rect::MakeXYWH(0, 0, 100, 100));
  auto geometry = Geometry::MakeFillPath(path);
  auto contents = PathSdfContents::Make(std::move(geometry), Color::Red());
  ASSERT_TRUE(contents);

  Entity entity;
  auto coverage = contents->GetCoverage(entity);
  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeXYWH(0, 0, 100, 100));
}

}  // namespace testing
}  // namespace impeller
