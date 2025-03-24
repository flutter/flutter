// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/line_contents.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

namespace impeller {
namespace testing {

TEST(LineContents, Create) {
  Path path;
  Scalar width = 5.0f;
  auto geometry = std::make_unique<LineGeometry>(
      /*p0=*/Point{0, 0},      //
      /*p1=*/Point{100, 100},  //
      /*width=*/width,         //
      /*cap=*/Cap::kSquare);
  std::unique_ptr<LineContents> contents =
      LineContents::Make(std::move(geometry), Color(1.f, 0.f, 0.f, 1.f));
  EXPECT_TRUE(contents);
  Entity entity;
  std::optional<Rect> coverage = contents->GetCoverage(entity);
  EXPECT_TRUE(coverage.has_value());
  if (coverage.has_value()) {
    Scalar lip = sqrt((width * width) / 2.f);
    EXPECT_EQ(*coverage,
              Rect::MakeXYWH(-lip, -lip, 100 + 2 * lip, 100 + 2 * lip));
  }
}

}  // namespace testing
}  // namespace impeller
