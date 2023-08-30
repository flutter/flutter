// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/stopwatch_dl.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

static SkRect MakeRectFromVertices(SkPoint vertices[6]) {
  // "Combine" the vertices to form a rectangle.
  auto const left = std::min(vertices[0].x(), vertices[5].x());
  auto const top = std::min(vertices[0].y(), vertices[1].y());
  auto const right = std::max(vertices[1].x(), vertices[2].x());
  auto const bottom = std::max(vertices[2].y(), vertices[3].y());

  return SkRect::MakeLTRB(left, top, right, bottom);
}

TEST(DlVertexPainter, DrawRectIntoVertices) {
  auto painter = DlVertexPainter();

  // Paint a red rectangle.
  painter.DrawRect(SkRect::MakeLTRB(0, 0, 10, 10), DlColor::kRed());

  // Paint a blue rectangle.
  painter.DrawRect(SkRect::MakeLTRB(10, 10, 20, 20), DlColor::kBlue());

  // Convert the buffered vertices into a |DlVertices| object.
  auto vertices = painter.IntoVertices();

  // Verify the vertices.
  EXPECT_EQ(vertices->mode(), DlVertexMode::kTriangles);
  EXPECT_EQ(vertices->vertex_count(), 3 * 2 * 2);

  auto const points = vertices->vertices();

  {
    // Extract the first 6 vertices (first rectangle).
    SkPoint first_rect_vertices[6];
    std::copy(points, points + 6, first_rect_vertices);
    EXPECT_EQ(MakeRectFromVertices(first_rect_vertices),
              SkRect::MakeLTRB(0, 0, 10, 10));
  }

  {
    // Extract the next 6 vertices (second rectangle).
    SkPoint second_rect_vertices[6];
    std::copy(points + 6, points + 12, second_rect_vertices);
    EXPECT_EQ(MakeRectFromVertices(second_rect_vertices),
              SkRect::MakeLTRB(10, 10, 20, 20));
  }

  // Verify the colors (first 6 vertices are red, next 6 are blue).
  auto const colors = vertices->colors();
  EXPECT_EQ(colors[0], DlColor::kRed());
  EXPECT_EQ(colors[1], DlColor::kRed());
  EXPECT_EQ(colors[2], DlColor::kRed());
  EXPECT_EQ(colors[3], DlColor::kRed());
  EXPECT_EQ(colors[4], DlColor::kRed());
  EXPECT_EQ(colors[5], DlColor::kRed());

  EXPECT_EQ(colors[6], DlColor::kBlue());
  EXPECT_EQ(colors[7], DlColor::kBlue());
  EXPECT_EQ(colors[8], DlColor::kBlue());
  EXPECT_EQ(colors[9], DlColor::kBlue());
  EXPECT_EQ(colors[10], DlColor::kBlue());
  EXPECT_EQ(colors[11], DlColor::kBlue());
}

}  // namespace testing
}  // namespace flutter
