// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/geometry/geometry_asserts.h"

namespace impeller {
namespace testing {

class MorphologyFilterContentsTest : public EntityPlayground {
 public:
  std::shared_ptr<Texture> MakeTexture(ISize size) {
    std::shared_ptr<CommandBuffer> command_buffer =
        GetContentContext()->GetContext()->CreateCommandBuffer();
    if (!command_buffer) {
      return nullptr;
    }

    auto render_target = GetContentContext()->MakeSubpass(
        "Clear Subpass", size, command_buffer,
        [](const ContentContext&, RenderPass&) { return true; });

    if (!GetContentContext()
             ->GetContext()
             ->GetCommandQueue()
             ->Submit(/*buffers=*/{command_buffer})
             .ok()) {
      return nullptr;
    }

    if (render_target.ok()) {
      return render_target.value().GetRenderTargetTexture();
    }
    return nullptr;
  }
};

INSTANTIATE_PLAYGROUND_SUITE(MorphologyFilterContentsTest);

TEST_P(MorphologyFilterContentsTest, RenderCoverageMatchesGetCoverage) {
  std::shared_ptr<Texture> texture = MakeTexture(ISize(100, 100));
  ASSERT_NE(texture, nullptr);
  auto contents = FilterContents::MakeDirectionalMorphology(
      FilterInput::Make(texture), Radius{2.0}, Vector2(1, 0),
      FilterContents::MorphType::kDilate);

  Entity entity;
  std::shared_ptr<ContentContext> renderer = GetContentContext();
  std::optional<Entity> result =
      contents->GetEntity(*renderer, entity, /*coverage_hint=*/{});

  ASSERT_TRUE(result.has_value());
  if (result.has_value()) {
    std::optional<Rect> result_coverage = result.value().GetCoverage();
    std::optional<Rect> contents_coverage = contents->GetCoverage(entity);
    Rect expected = Rect::MakeLTRB(-2, 0, 102, 100);
    ASSERT_TRUE(result_coverage.has_value());
    ASSERT_TRUE(contents_coverage.has_value());
    if (result_coverage.has_value() && contents_coverage.has_value()) {
      EXPECT_TRUE(RectNear(result_coverage.value(), expected));
      EXPECT_TRUE(RectNear(contents_coverage.value(), expected));
    }
  }
}

TEST_P(MorphologyFilterContentsTest,
       RenderDilateWithFractionalCoverageIsSymmetric) {
  // Non-integer scale and radius produce a fractional pixel expansion
  // 1.5 * 2.625 = 3.9375, exercising the render target ceiling logic.
  Scalar radius = 1.5;
  Scalar scale = 2.625;

  std::shared_ptr<Texture> texture = MakeTexture(ISize(100, 100));
  ASSERT_NE(texture, nullptr);
  auto contents = FilterContents::MakeDirectionalMorphology(
      FilterInput::Make(texture), Radius{radius}, Vector2(1, 0),
      FilterContents::MorphType::kDilate);
  contents->SetEffectTransform(Matrix::MakeScale(Vector2(scale, scale)));

  Entity entity;
  std::shared_ptr<ContentContext> renderer = GetContentContext();
  std::optional<Entity> result =
      contents->GetEntity(*renderer, entity, /*coverage_hint=*/{});

  ASSERT_TRUE(result.has_value());
  if (result.has_value()) {
    std::optional<Rect> result_coverage = result->GetCoverage();
    ASSERT_TRUE(result_coverage.has_value());
    if (result_coverage.has_value()) {
      Scalar expected_expansion = radius * scale;
      EXPECT_TRUE(result_coverage->Contains(Rect::MakeLTRB(
          -expected_expansion, 0, 100 + expected_expansion, 100)));
      Scalar left_expansion = 0 - result_coverage->GetLeft();
      Scalar right_expansion = result_coverage->GetRight() - 100;
      EXPECT_NEAR(left_expansion, right_expansion, 0.5);
    }
  }
}

TEST_P(MorphologyFilterContentsTest,
       RenderDilateYWithFractionalCoverageIsSymmetric) {
  // Non-integer scale and radius produce a fractional pixel expansion
  // 1.5 * 2.625 = 3.9375, exercising the render target ceiling logic.
  Scalar radius = 1.5;
  Scalar scale = 2.625;

  std::shared_ptr<Texture> texture = MakeTexture(ISize(100, 100));
  ASSERT_NE(texture, nullptr);
  auto contents = FilterContents::MakeDirectionalMorphology(
      FilterInput::Make(texture), Radius{radius}, Vector2(0, 1),
      FilterContents::MorphType::kDilate);
  contents->SetEffectTransform(Matrix::MakeScale(Vector2(scale, scale)));

  Entity entity;
  std::shared_ptr<ContentContext> renderer = GetContentContext();
  std::optional<Entity> result =
      contents->GetEntity(*renderer, entity, /*coverage_hint=*/{});

  ASSERT_TRUE(result.has_value());
  if (result.has_value()) {
    std::optional<Rect> result_coverage = result->GetCoverage();
    ASSERT_TRUE(result_coverage.has_value());
    if (result_coverage.has_value()) {
      Scalar expected_expansion = radius * scale;
      EXPECT_TRUE(result_coverage->Contains(Rect::MakeLTRB(
          0, -expected_expansion, 100, 100 + expected_expansion)));
      Scalar top_expansion = 0 - result_coverage->GetTop();
      Scalar bottom_expansion = result_coverage->GetBottom() - 100;
      EXPECT_NEAR(top_expansion, bottom_expansion, 0.5);
    }
  }
}

}  // namespace testing
}  // namespace impeller
