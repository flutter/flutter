// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {
namespace testing {

TEST(TessellatorTest, TessellatorReturnsCorrectResultStatus) {
  // Zero points.
  {
    Tessellator t;
    auto polyline = PathBuilder{}.TakePath().CreatePolyline();
    Tessellator::Result result =
        t.Tessellate(FillType::kPositive, polyline, [](Point point) {});

    ASSERT_EQ(polyline.points.size(), 0u);
    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }

  // One point.
  {
    Tessellator t;
    auto polyline = PathBuilder{}.LineTo({0, 0}).TakePath().CreatePolyline();
    Tessellator::Result result =
        t.Tessellate(FillType::kPositive, polyline, [](Point point) {});

    ASSERT_EQ(polyline.points.size(), 1u);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Two points.
  {
    Tessellator t;
    auto polyline =
        PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath().CreatePolyline();
    Tessellator::Result result =
        t.Tessellate(FillType::kPositive, polyline, [](Point point) {});

    ASSERT_EQ(polyline.points.size(), 2u);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }
}

}  // namespace testing
}  // namespace impeller
