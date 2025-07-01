// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/dl_sampling_options.h"
#include "display_list/dl_tile_mode.h"
#include "display_list/effects/dl_color_source.h"
#include "display_list/effects/dl_mask_filter.h"
#include "flutter/impeller/display_list/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/impeller/entity/geometry/shadow_path_geometry.h"
#include "flutter/testing/testing.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/playground/widgets.h"
#include "impeller/tessellator/path_tessellator.h"

namespace impeller {
namespace testing {

using namespace flutter;

namespace {
void DrawShadowMesh(DisplayListBuilder& builder,
                    const DlPath& path,
                    Scalar elevation,
                    Scalar dpr,
                    bool use_skia) {
  std::shared_ptr<ShadowVertices> shadow_vertices;
  DlPaint paint;
  paint.setDrawStyle(DlDrawStyle::kStroke);
  bool should_optimize = path.IsConvex();
  Point shadow_translate;
  Point path_translate = Point(0, elevation * dpr * 0.5f);

  if (use_skia) {
#if EXPORT_SKIA_SHADOW
    shadow_vertices =
        ShadowPathGeometry::MakeAmbientShadowVerticesSkia(path, elevation, {});
    paint.setColor(should_optimize ? DlColor::kDarkGreen() : DlColor::kRed());
#else
    return;
#endif
  } else {
    Tessellator tessellator;
    shadow_vertices = ShadowPathGeometry::MakeAmbientShadowVertices(
        tessellator, path, elevation, {});
    EXPECT_EQ(shadow_vertices != nullptr, should_optimize);
    shadow_translate = path_translate;
    paint.setColor(DlColor::kDarkGrey());
  }

  if (shadow_vertices) {
    builder.Save();
    builder.Translate(shadow_translate.x, shadow_translate.y);
    auto indices = shadow_vertices->GetIndices();
    auto vertices = shadow_vertices->GetVertices();
    DlPathBuilder mesh_builder;
    for (size_t i = 0; i < shadow_vertices->GetIndexCount(); i += 3) {
      mesh_builder.MoveTo(vertices[indices[i + 0]]);
      mesh_builder.LineTo(vertices[indices[i + 1]]);
      mesh_builder.LineTo(vertices[indices[i + 2]]);
      mesh_builder.Close();
    }
    DlPath mesh_path = mesh_builder.TakePath();
    builder.DrawPath(mesh_path, paint);
    builder.Restore();
  }

  builder.Save();
  builder.Translate(path_translate.x, path_translate.y);
  paint.setColor(DlColor::kPurple());
  builder.DrawPath(path, paint);
  builder.Restore();
}

void DrawShadowAndCompareMeshes(DisplayListBuilder& builder,
                                const DlPath& path,
                                Scalar elevation,
                                Scalar dpr) {
  builder.DrawShadow(path, DlColor::kBlue(), elevation, true, dpr);

  DlPathBuilder path_builder;
  path_builder.AddPath(path);
  // A single line contour won't make any visible change to the shadow,
  // but none of the shadow to mesh converters will touch a path that
  // has multiple contours so this path should always default to the
  // general shadow code based on a blur filter.
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(1, 1));
  DlPath complex_path = path_builder.TakePath();

  builder.Translate(300, 0);
  builder.DrawShadow(complex_path, DlColor::kBlue(), elevation, true, dpr);
  builder.Translate(-300, 0);

  builder.Translate(0, 300);
  builder.DrawShadow(path, DlColor::kBlue(), elevation, true, dpr);
  DrawShadowMesh(builder, path, elevation, dpr, false);
  builder.Translate(300, 0);
  builder.DrawShadow(complex_path, DlColor::kBlue(), elevation, true, dpr);
  DrawShadowMesh(builder, path, elevation, dpr, true);
  builder.Translate(-300, -300);
}
}  // namespace

TEST_P(AiksTest, DrawShadowDoesNotOptimizeHourglass) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.LineTo(DlPoint(300, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowDoesNotOptimizeInnerOuterSpiral) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;
  int step_count = 20;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(300, 200));
  for (int i = 1; i < step_count * 2; i++) {
    Scalar angle = (k2Pi * i) / step_count;
    Scalar radius = 80.0f + std::abs(i - step_count);
    path_builder.LineTo(DlPoint(200, 200) + DlPoint(std::cos(angle) * radius,
                                                    std::sin(angle) * radius));
  }
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowDoesNotOptimizeOuterInnerSpiral) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;
  int step_count = 20;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(280, 200));
  for (int i = 1; i < step_count * 2; i++) {
    Scalar angle = (k2Pi * i) / step_count;
    Scalar radius = 100.0f - std::abs(i - step_count);
    path_builder.LineTo(DlPoint(200, 200) + DlPoint(std::cos(angle) * radius,
                                                    std::sin(angle) * radius));
  }
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowDoesNotOptimizeMultipleContours) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(150, 100));
  path_builder.LineTo(DlPoint(200, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();
  path_builder.MoveTo(DlPoint(250, 100));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(200, 300));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseTriangle) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseTriangle) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseRect) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(300, 100));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseRect) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(300, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseQuadratic) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.QuadraticCurveTo(DlPoint(300, 100), DlPoint(300, 200));
  path_builder.QuadraticCurveTo(DlPoint(300, 300), DlPoint(200, 300));
  path_builder.QuadraticCurveTo(DlPoint(100, 300), DlPoint(100, 200));
  path_builder.QuadraticCurveTo(DlPoint(100, 100), DlPoint(200, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseQuadratic) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.QuadraticCurveTo(DlPoint(100, 100), DlPoint(100, 200));
  path_builder.QuadraticCurveTo(DlPoint(100, 300), DlPoint(200, 300));
  path_builder.QuadraticCurveTo(DlPoint(300, 300), DlPoint(300, 200));
  path_builder.QuadraticCurveTo(DlPoint(300, 100), DlPoint(200, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseConic) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.ConicCurveTo(DlPoint(300, 100), DlPoint(300, 200), 0.4f);
  path_builder.ConicCurveTo(DlPoint(300, 300), DlPoint(200, 300), 0.4f);
  path_builder.ConicCurveTo(DlPoint(100, 300), DlPoint(100, 200), 0.4f);
  path_builder.ConicCurveTo(DlPoint(100, 100), DlPoint(200, 100), 0.4f);
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseConic) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.ConicCurveTo(DlPoint(100, 100), DlPoint(100, 200), 0.4f);
  path_builder.ConicCurveTo(DlPoint(100, 300), DlPoint(200, 300), 0.4f);
  path_builder.ConicCurveTo(DlPoint(300, 300), DlPoint(300, 200), 0.4f);
  path_builder.ConicCurveTo(DlPoint(300, 100), DlPoint(200, 100), 0.4f);
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseCubic) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.CubicCurveTo(DlPoint(280, 100), DlPoint(300, 120),
                            DlPoint(300, 200));
  path_builder.CubicCurveTo(DlPoint(300, 280), DlPoint(280, 300),
                            DlPoint(200, 300));
  path_builder.CubicCurveTo(DlPoint(120, 300), DlPoint(100, 280),
                            DlPoint(100, 200));
  path_builder.CubicCurveTo(DlPoint(100, 120), DlPoint(120, 100),
                            DlPoint(200, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseCubic) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.CubicCurveTo(DlPoint(120, 100), DlPoint(100, 120),
                            DlPoint(100, 200));
  path_builder.CubicCurveTo(DlPoint(100, 280), DlPoint(120, 300),
                            DlPoint(200, 300));
  path_builder.CubicCurveTo(DlPoint(280, 300), DlPoint(300, 280),
                            DlPoint(300, 200));
  path_builder.CubicCurveTo(DlPoint(300, 120), DlPoint(280, 100),
                            DlPoint(200, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeWithExtraneousMoveTos) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.MoveTo(DlPoint(1000, 1000));
  path_builder.MoveTo(DlPoint(100, 50));
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();
  path_builder.MoveTo(DlPoint(1000, 1000));
  path_builder.MoveTo(DlPoint(500, 300));
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseWithExtraColinearVertices) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(250, 200));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(200, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.LineTo(DlPoint(150, 200));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest,
       DrawShadowCanOptimizeCounterClockwiseWithExtraColinearVertices) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(150, 200));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.LineTo(DlPoint(200, 300));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(250, 200));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

}  // namespace testing
}  // namespace impeller
