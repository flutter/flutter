// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {
namespace testing {

TEST(TessellatorTest, TessellatorBuilderReturnsCorrectResultStatus) {
  // Zero points.
  {
    Tessellator t;
    auto polyline = PathBuilder{}.TakePath().CreatePolyline(1.0f);
    Tessellator::Result result = t.Tessellate(
        FillType::kPositive, polyline,
        [](const float* vertices, size_t vertices_size, const uint16_t* indices,
           size_t indices_size) { return true; });

    ASSERT_EQ(polyline.points.size(), 0u);
    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }

  // One point.
  {
    Tessellator t;
    auto polyline =
        PathBuilder{}.LineTo({0, 0}).TakePath().CreatePolyline(1.0f);
    Tessellator::Result result = t.Tessellate(
        FillType::kPositive, polyline,
        [](const float* vertices, size_t vertices_size, const uint16_t* indices,
           size_t indices_size) { return true; });
    ASSERT_EQ(polyline.points.size(), 1u);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Two points.
  {
    Tessellator t;
    auto polyline =
        PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath().CreatePolyline(1.0f);
    Tessellator::Result result = t.Tessellate(
        FillType::kPositive, polyline,
        [](const float* vertices, size_t vertices_size, const uint16_t* indices,
           size_t indices_size) { return true; });

    ASSERT_EQ(polyline.points.size(), 2u);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Many points.
  {
    Tessellator t;
    PathBuilder builder;
    for (int i = 0; i < 1000; i++) {
      auto coord = i * 1.0f;
      builder.AddLine({coord, coord}, {coord + 1, coord + 1});
    }
    auto polyline = builder.TakePath().CreatePolyline(1.0f);
    Tessellator::Result result = t.Tessellate(
        FillType::kPositive, polyline,
        [](const float* vertices, size_t vertices_size, const uint16_t* indices,
           size_t indices_size) { return true; });

    ASSERT_EQ(polyline.points.size(), 2000u);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Closure fails.
  {
    Tessellator t;
    auto polyline =
        PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath().CreatePolyline(1.0f);
    Tessellator::Result result = t.Tessellate(
        FillType::kPositive, polyline,
        [](const float* vertices, size_t vertices_size, const uint16_t* indices,
           size_t indices_size) { return false; });

    ASSERT_EQ(polyline.points.size(), 2u);
    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }
}

}  // namespace testing
}  // namespace impeller
