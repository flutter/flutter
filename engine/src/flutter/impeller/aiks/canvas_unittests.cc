// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/aiks/aiks_unittests.h"
#include "impeller/aiks/experimental_canvas.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path_builder.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace impeller {
namespace testing {

std::unique_ptr<ExperimentalCanvas> CreateTestCanvas(
    ContentContext& context,
    std::optional<Rect> cull_rect = std::nullopt) {
  RenderTarget render_target = context.GetRenderTargetCache()->CreateOffscreen(
      *context.GetContext(), {1, 1}, 1);

  if (cull_rect.has_value()) {
    return std::make_unique<ExperimentalCanvas>(context, render_target, false,
                                                cull_rect.value());
  }
  return std::make_unique<ExperimentalCanvas>(context, render_target, false);
}

TEST_P(AiksTest, TransformMultipliesCorrectly) {
  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);

  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(), Matrix());

  // clang-format off
  canvas->Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(  1,   0,   0,   0,
             0,   1,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas->Rotate(Radians(kPiOver2));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(  0,   1,   0,   0,
            -1,   0,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas->Scale(Vector3(2, 3));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(  0,   2,   0,   0,
            -3,   0,   0,   0,
             0,   0,   0,   0,
           100, 200,   0,   1));

  canvas->Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(   0,   2,   0,   0,
             -3,   0,   0,   0,
              0,   0,   0,   0,
           -500, 400,   0,   1));
  // clang-format on
}

TEST_P(AiksTest, CanvasCanPushPopCTM) {
  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);

  ASSERT_EQ(canvas->GetSaveCount(), 1u);
  ASSERT_EQ(canvas->Restore(), false);

  canvas->Translate(Size{100, 100});
  canvas->Save(10);
  ASSERT_EQ(canvas->GetSaveCount(), 2u);
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
  ASSERT_TRUE(canvas->Restore());
  ASSERT_EQ(canvas->GetSaveCount(), 1u);
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, CanvasCTMCanBeUpdated) {
  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);

  Matrix identity;
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(), identity);
  canvas->Translate(Size{100, 100});
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, EmptyCullRect) {
  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);

  ASSERT_FALSE(canvas->GetCurrentLocalCullingBounds().has_value());
}

TEST_P(AiksTest, InitialCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), initial_cull);
}

TEST_P(AiksTest, TranslatedCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  Rect translated_cull = Rect::MakeXYWH(0, 0, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->Translate(Vector3(5, 5, 0));

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), translated_cull);
}

TEST_P(AiksTest, ScaledCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  Rect scaled_cull = Rect::MakeXYWH(10, 10, 20, 20);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->Scale(Vector2(0.5, 0.5));

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), scaled_cull);
}

TEST_P(AiksTest, RectClipIntersectAgainstEmptyCullRect) {
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kIntersect);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), rect_clip);
}

TEST_P(AiksTest, RectClipDiffAgainstEmptyCullRect) {
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_FALSE(canvas->GetCurrentLocalCullingBounds().has_value());
}

TEST_P(AiksTest, RectClipIntersectAgainstCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);
  Rect result_cull = Rect::MakeXYWH(5, 5, 5, 5);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kIntersect);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffAgainstNonCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffAboveCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(0, 0, 20, 4);
  Rect result_cull = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffBelowCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(0, 16, 20, 4);
  Rect result_cull = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffLeftOfCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(0, 0, 4, 20);
  Rect result_cull = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffRightOfCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(16, 0, 4, 20);
  Rect result_cull = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffAgainstVCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, 0, 10, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 5, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RectClipDiffAgainstHCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(0, 5, 10, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 10, 5);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRect(rect_clip, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RRectClipIntersectAgainstEmptyCullRect) {
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kIntersect);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), rect_clip);
}

TEST_P(AiksTest, RRectClipDiffAgainstEmptyCullRect) {
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kDifference);

  ASSERT_FALSE(canvas->GetCurrentLocalCullingBounds().has_value());
}

TEST_P(AiksTest, RRectClipIntersectAgainstCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);
  Rect result_cull = Rect::MakeXYWH(5, 5, 5, 5);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kIntersect);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RRectClipDiffAgainstNonCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RRectClipDiffAgainstVPartiallyCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, 0, 10, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 6, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RRectClipDiffAgainstVFullyCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(5, -2, 10, 14);
  Rect result_cull = Rect::MakeXYWH(0, 0, 5, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RRectClipDiffAgainstHPartiallyCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(0, 5, 10, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 10, 6);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, RRectClipDiffAgainstHFullyCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  Rect rect_clip = Rect::MakeXYWH(-2, 5, 14, 10);
  Rect result_cull = Rect::MakeXYWH(0, 0, 10, 5);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipRRect(rect_clip, {1, 1}, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, PathClipIntersectAgainstEmptyCullRect) {
  PathBuilder builder;
  builder.AddRect(Rect::MakeXYWH(5, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(5, 14, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 14, 1, 1));
  Path path = builder.TakePath();
  Rect rect_clip = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);
  canvas->ClipPath(path, Entity::ClipOperation::kIntersect);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), rect_clip);
}

TEST_P(AiksTest, PathClipDiffAgainstEmptyCullRect) {
  PathBuilder builder;
  builder.AddRect(Rect::MakeXYWH(5, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(5, 14, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 14, 1, 1));
  Path path = builder.TakePath();

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context);
  canvas->ClipPath(path, Entity::ClipOperation::kDifference);

  ASSERT_FALSE(canvas->GetCurrentLocalCullingBounds().has_value());
}

TEST_P(AiksTest, PathClipIntersectAgainstCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  PathBuilder builder;
  builder.AddRect(Rect::MakeXYWH(5, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(5, 14, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 14, 1, 1));
  Path path = builder.TakePath();
  Rect result_cull = Rect::MakeXYWH(5, 5, 5, 5);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipPath(path, Entity::ClipOperation::kIntersect);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, PathClipDiffAgainstNonCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(0, 0, 10, 10);
  PathBuilder builder;
  builder.AddRect(Rect::MakeXYWH(5, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(5, 14, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 5, 1, 1));
  builder.AddRect(Rect::MakeXYWH(14, 14, 1, 1));
  Path path = builder.TakePath();
  Rect result_cull = Rect::MakeXYWH(0, 0, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipPath(path, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

TEST_P(AiksTest, PathClipDiffAgainstFullyCoveredCullRect) {
  Rect initial_cull = Rect::MakeXYWH(5, 5, 10, 10);
  PathBuilder builder;
  builder.AddRect(Rect::MakeXYWH(0, 0, 100, 100));
  Path path = builder.TakePath();
  // Diff clip of Paths is ignored due to complexity
  Rect result_cull = Rect::MakeXYWH(5, 5, 10, 10);

  ContentContext context(GetContext(), nullptr);
  auto canvas = CreateTestCanvas(context, initial_cull);
  canvas->ClipPath(path, Entity::ClipOperation::kDifference);

  ASSERT_TRUE(canvas->GetCurrentLocalCullingBounds().has_value());
  ASSERT_EQ(canvas->GetCurrentLocalCullingBounds().value(), result_cull);
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)
