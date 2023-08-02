// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/geometry_asserts.h"

namespace impeller {
namespace testing {

TEST(FilterInputTest, CanSetLocalTransformForTexture) {
  std::shared_ptr<Texture> texture = nullptr;
  auto input =
      FilterInput::Make(texture, Matrix::MakeTranslation({1.0, 0.0, 0.0}));
  Entity e;
  e.SetTransformation(Matrix::MakeTranslation({0.0, 2.0, 0.0}));

  ASSERT_MATRIX_NEAR(input->GetLocalTransform(e),
                     Matrix::MakeTranslation({1.0, 0.0, 0.0}));
  ASSERT_MATRIX_NEAR(input->GetTransform(e),
                     Matrix::MakeTranslation({1.0, 2.0, 0.0}));
}

TEST(FilterInputTest, IsLeaf) {
  std::shared_ptr<FilterContents> leaf =
      ColorFilterContents::MakeBlend(BlendMode::kSource, {});
  ASSERT_TRUE(leaf->IsLeaf());

  auto base = ColorFilterContents::MakeMatrixFilter(
      FilterInput::Make(leaf), Matrix(), {}, Matrix(), false);

  ASSERT_TRUE(leaf->IsLeaf());
  ASSERT_FALSE(base->IsLeaf());
}

TEST(FilterInputTest, SetCoverageInputs) {
  std::shared_ptr<FilterContents> leaf =
      ColorFilterContents::MakeBlend(BlendMode::kSource, {});
  ASSERT_TRUE(leaf->IsLeaf());

  auto base = ColorFilterContents::MakeMatrixFilter(
      FilterInput::Make(leaf), Matrix(), {}, Matrix(), false);

  {
    auto result = base->GetCoverage({});
    ASSERT_FALSE(result.has_value());
  }

  auto coverage_rect = Rect::MakeLTRB(100, 100, 200, 200);
  base->SetLeafInputs(FilterInput::Make({coverage_rect}));

  {
    auto result = base->GetCoverage({});
    ASSERT_TRUE(result.has_value());
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
    ASSERT_RECT_NEAR(result.value(), coverage_rect);
  }
}

}  // namespace testing
}  // namespace impeller
