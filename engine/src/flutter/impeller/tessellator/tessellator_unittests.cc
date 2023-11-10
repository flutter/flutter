// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {
namespace testing {

TEST(TessellatorTest, TessellatorBuilderReturnsCorrectResultStatus) {
  // Zero points.
  {
    Tessellator t;
    auto path = PathBuilder{}.TakePath(FillType::kPositive);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }

  // One point.
  {
    Tessellator t;
    auto path = PathBuilder{}.LineTo({0, 0}).TakePath(FillType::kPositive);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Two points.
  {
    Tessellator t;
    auto path =
        PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath(FillType::kPositive);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

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
    auto path = builder.TakePath(FillType::kPositive);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Closure fails.
  {
    Tessellator t;
    auto path =
        PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath(FillType::kPositive);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return false; });

    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }

  // More than 30 contours, non-zero fill mode.
  {
    Tessellator t;
    PathBuilder builder = {};
    for (auto i = 0u; i < Tessellator::kMultiContourThreshold + 1; i++) {
      builder.AddCircle(Point(i, i), 4);
    }
    auto path = builder.TakePath(FillType::kNonZero);
    bool no_indices = false;
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [&no_indices](const float* vertices, size_t vertices_count,
                      const uint16_t* indices, size_t indices_count) {
          no_indices = indices == nullptr;
          return true;
        });

    ASSERT_TRUE(no_indices);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // More than uint16 points, odd fill mode.
  {
    Tessellator t;
    PathBuilder builder = {};
    for (auto i = 0; i < 1000; i++) {
      builder.AddCircle(Point(i, i), 4);
    }
    auto path = builder.TakePath(FillType::kOdd);
    bool no_indices = false;
    size_t count = 0u;
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [&no_indices, &count](const float* vertices, size_t vertices_count,
                              const uint16_t* indices, size_t indices_count) {
          no_indices = indices == nullptr;
          count = vertices_count;
          return true;
        });

    ASSERT_TRUE(no_indices);
    ASSERT_TRUE(count >= USHRT_MAX);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }
}

TEST(TessellatorTest, TessellateConvex) {
  {
    Tessellator t;
    // Sanity check simple rectangle.
    auto [pts, indices] = t.TessellateConvex(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 10, 10)).TakePath(), 1.0);

    std::vector<Point> expected = {
        {0, 0}, {10, 0}, {10, 10}, {0, 10},  //
    };
    std::vector<uint16_t> expected_indices = {0, 1, 2, 0, 2, 3};
    ASSERT_EQ(pts, expected);
    ASSERT_EQ(indices, expected_indices);
  }

  {
    Tessellator t;
    auto [pts, indices] =
        t.TessellateConvex(PathBuilder{}
                               .AddRect(Rect::MakeLTRB(0, 0, 10, 10))
                               .AddRect(Rect::MakeLTRB(20, 20, 30, 30))
                               .TakePath(),
                           1.0);

    std::vector<Point> expected = {
        {0, 0},   {10, 0},  {10, 10}, {0, 10},  //
        {20, 20}, {30, 20}, {30, 30}, {20, 30}  //
    };
    std::vector<uint16_t> expected_indices = {0, 1, 2, 0, 2, 3,
                                              0, 6, 7, 0, 7, 8};
    ASSERT_EQ(pts, expected);
    ASSERT_EQ(indices, expected_indices);
  }
}

}  // namespace testing
}  // namespace impeller
