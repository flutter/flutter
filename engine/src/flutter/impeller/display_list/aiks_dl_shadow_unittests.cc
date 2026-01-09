// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/display_list/aiks_unittests.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/impeller/entity/geometry/shadow_path_geometry.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

using namespace flutter;

namespace {
/// @brief  Reflect the segments of a path around a coordinate using the
///         PathReceiver interface.
class PathReflector : public PathReceiver {
 public:
  /// Reflect a path horizontally around the given x coordinate.
  static PathReflector ReflectAroundX(Scalar x_coordinate) {
    return PathReflector(-1.0f, x_coordinate * 2.0f, 1.0f, 0.0f);
  }

  /// Reflect a path vertically around the given y coordinate.
  static PathReflector ReflectAroundY(Scalar y_coordinate) {
    return PathReflector(1.0f, 0.0f, -1.0f, y_coordinate * 2.0f);
  }

  /// Reflect a path horizontally and vertically around the given coordinate.
  static PathReflector ReflectAround(const Point& anchor) {
    return PathReflector(-1.0f, anchor.x * 2.0f, -1.0f, anchor.y * 2.0f);
  }

  // |PathReceiver|
  void MoveTo(const Point& p2, bool will_be_closed) override {
    path_builder_.MoveTo(reflect(p2));
  }

  // |PathReceiver|
  void LineTo(const Point& p2) override { path_builder_.LineTo(reflect(p2)); }

  // |PathReceiver|
  void QuadTo(const Point& cp, const Point& p2) override {
    path_builder_.QuadraticCurveTo(reflect(cp), reflect(p2));
  }

  // |PathReceiver|
  bool ConicTo(const Point& cp, const Point& p2, Scalar weight) override {
    path_builder_.ConicCurveTo(reflect(cp), reflect(p2), weight);
    return true;
  }

  // |PathReceiver|
  void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) override {
    path_builder_.CubicCurveTo(reflect(cp1), reflect(cp2), reflect(p2));
  }

  // |PathReceiver|
  void Close() override { path_builder_.Close(); }

  DlPath TakePath() { return path_builder_.TakePath(); }

 private:
  PathReflector(Scalar scale_x,
                Scalar translate_x,
                Scalar scale_y,
                Scalar translate_y)
      : scale_x_(scale_x),
        translate_x_(translate_x),
        scale_y_(scale_y),
        translate_y_(translate_y) {}

  const Scalar scale_x_;
  const Scalar translate_x_;
  const Scalar scale_y_;
  const Scalar translate_y_;

  DlPoint reflect(const DlPoint& in_point) {
    return DlPoint(in_point.x * scale_x_ + translate_x_,
                   in_point.y * scale_y_ + translate_y_);
  }

  DlPathBuilder path_builder_;
};

DlPath ReflectPath(const DlPath& path) {
  PathReflector reflector =
      PathReflector::ReflectAroundY(path.GetBounds().GetCenter().y);
  path.Dispatch(reflector);
  return reflector.TakePath();
}

void DrawShadowMesh(DisplayListBuilder& builder,
                    const DlPath& path,
                    Scalar elevation,
                    Scalar dpr) {
  bool should_optimize = path.IsConvex();
  Matrix matrix = builder.GetMatrix();

  // From dl_dispatcher, making a MaskFilter.
  Scalar light_radius = 800 / 600;
  EXPECT_EQ(light_radius, 1.0f);  // Value in dl_dispatcher is bad.
  Scalar occluder_z = elevation * dpr;
  Radius radius = Radius{light_radius * occluder_z / matrix.GetScale().y};
  Sigma sigma = radius;

  // From canvas.cc computing the device radius.
  Scalar device_radius = sigma.sigma * 2.8 * matrix.GetMaxBasisLengthXY();

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path,
                                                    device_radius, matrix);
  EXPECT_EQ(shadow_vertices != nullptr, should_optimize);
  Point shadow_translate = Point(0, occluder_z) * matrix.Invert().GetScale().y;

  DlPaint paint;
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setColor(DlColor::kDarkGrey());

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
  builder.Translate(shadow_translate.x, shadow_translate.y);
  paint.setColor(DlColor::kPurple());
  builder.DrawPath(path, paint);
  builder.Restore();
}

DlPath MakeComplexPath(const DlPath& path) {
  DlPathBuilder path_builder;
  path_builder.AddPath(path);
  // A single line contour won't make any visible change to the shadow,
  // but none of the shadow to mesh converters will touch a path that
  // has multiple contours so this path should always default to the
  // general shadow code based on a blur filter.
  path_builder.LineTo(DlPoint(0, 0));
  return path_builder.TakePath();
}

void DrawShadowAndCompareMeshes(DisplayListBuilder& builder,
                                const DlPath& path,
                                Scalar elevation,
                                Scalar dpr,
                                const DlPath* simple_path = nullptr) {
  DlPath complex_path = MakeComplexPath(path);

  builder.Save();

  if (simple_path) {
    builder.DrawShadow(*simple_path, DlColor::kBlue(), elevation, true, dpr);
  }

  builder.Translate(300, 0);
  builder.DrawShadow(path, DlColor::kBlue(), elevation, true, dpr);

  builder.Translate(300, 0);
  builder.DrawShadow(complex_path, DlColor::kBlue(), elevation, true, dpr);

  builder.Restore();
  builder.Translate(0, 300);
  builder.Save();

  // Draw the mesh wireframe underneath the regular path output in the
  // row above us.
  builder.Translate(300, 0);
  builder.DrawShadow(path, DlColor::kBlue(), elevation, true, dpr);
  DrawShadowMesh(builder, path, elevation, dpr);

  builder.Restore();
}

// Makes a Round Rect path using conics, but the weights on the corners is
// off by just a tiny amount so the path will not be recognized.
DlPath MakeAlmostRoundRectPath(const Rect& bounds,
                               const RoundingRadii& radii,
                               bool clockwise = true) {
  DlScalar left = bounds.GetLeft();
  DlScalar top = bounds.GetTop();
  DlScalar right = bounds.GetRight();
  DlScalar bottom = bounds.GetBottom();

  // A weight of sqrt(2)/2 is how you really perform conic circular sections,
  // but by tweaking it slightly the path will not be recognized as an oval
  // and accelerated.
  constexpr Scalar kWeight = kSqrt2Over2 - 0.0005f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(right - radii.top_right.width, top));
  path_builder.ConicCurveTo(DlPoint(right, top),
                            DlPoint(right, top + radii.top_right.height),
                            kWeight);
  path_builder.LineTo(DlPoint(right, bottom - radii.bottom_right.height));
  path_builder.ConicCurveTo(DlPoint(right, bottom),
                            DlPoint(right - radii.bottom_right.width, bottom),
                            kWeight);
  path_builder.LineTo(DlPoint(left + radii.bottom_left.width, bottom));
  path_builder.ConicCurveTo(DlPoint(left, bottom),
                            DlPoint(left, bottom - radii.bottom_left.height),
                            kWeight);
  path_builder.LineTo(DlPoint(left, top + radii.top_left.height));
  path_builder.ConicCurveTo(DlPoint(left, top),
                            DlPoint(left + radii.top_left.width, top),  //
                            kWeight);
  path_builder.Close();
  DlPath path = path_builder.TakePath();
  if (!clockwise) {
    path = ReflectPath(path);
  }
  return path;
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
  // Tweak one corner by a sub-pixel amount to prevent recognition as
  // a rectangle, but still generating a rectangular shadow.
  path_builder.LineTo(DlPoint(299.9, 100));
  path_builder.LineTo(DlPoint(300, 300));
  path_builder.LineTo(DlPoint(100, 300));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const DlPath simple_path = DlPath::MakeRectLTRB(100, 100, 300, 300);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

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
  // Tweak one corner by a sub-pixel amount to prevent recognition as
  // a rectangle, but still generating a rectangular shadow.
  path_builder.LineTo(DlPoint(299.9, 100));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const DlPath simple_path = DlPath::MakeRectLTRB(100, 100, 300, 300);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseCircle) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  // A weight of sqrt(2) is how you really perform conic circular sections,
  // but by tweaking it slightly the path will not be recognized as an oval
  // and accelerated.
  constexpr Scalar kWeight = kSqrt2Over2 - 0.0005f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.ConicCurveTo(DlPoint(300, 100), DlPoint(300, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(300, 300), DlPoint(200, 300), kWeight);
  path_builder.ConicCurveTo(DlPoint(100, 300), DlPoint(100, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(100, 100), DlPoint(200, 100), kWeight);
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const DlPath simple_path = DlPath::MakeCircle(DlPoint(200, 200), 100);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseCircle) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  // A weight of sqrt(2)/2 is how you really perform conic circular sections,
  // but by tweaking it slightly the path will not be recognized as an oval
  // and accelerated.
  constexpr Scalar kWeight = kSqrt2Over2 - 0.0005f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 100));
  path_builder.ConicCurveTo(DlPoint(100, 100), DlPoint(100, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(100, 300), DlPoint(200, 300), kWeight);
  path_builder.ConicCurveTo(DlPoint(300, 300), DlPoint(300, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(300, 100), DlPoint(200, 100), kWeight);
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const DlPath simple_path = DlPath::MakeCircle(DlPoint(200, 200), 100);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseOval) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  // A weight of sqrt(2) is how you really perform conic circular sections,
  // but by tweaking it slightly the path will not be recognized as an oval
  // and accelerated.
  constexpr Scalar kWeight = kSqrt2Over2 - 0.0005f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 120));
  path_builder.ConicCurveTo(DlPoint(300, 120), DlPoint(300, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(300, 280), DlPoint(200, 280), kWeight);
  path_builder.ConicCurveTo(DlPoint(100, 280), DlPoint(100, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(100, 120), DlPoint(200, 120), kWeight);
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const DlPath simple_path = DlPath::MakeOvalLTRB(100, 120, 300, 280);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseOval) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  // A weight of sqrt(2)/2 is how you really perform conic circular sections,
  // but by tweaking it slightly the path will not be recognized as an oval
  // and accelerated.
  constexpr Scalar kWeight = kSqrt2Over2 - 0.0005f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(200, 120));
  path_builder.ConicCurveTo(DlPoint(100, 120), DlPoint(100, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(100, 280), DlPoint(200, 280), kWeight);
  path_builder.ConicCurveTo(DlPoint(300, 280), DlPoint(300, 200), kWeight);
  path_builder.ConicCurveTo(DlPoint(300, 120), DlPoint(200, 120), kWeight);
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const DlPath simple_path = DlPath::MakeOvalLTRB(100, 120, 300, 280);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseUniformRoundRect) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPath path = MakeAlmostRoundRectPath(DlRect::MakeLTRB(100, 100, 300, 300),
                                        DlRoundingRadii::MakeRadius(30), true);

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const RoundRect round_rect =
      RoundRect::MakeRectRadius(Rect::MakeLTRB(100, 100, 300, 300), 30);
  const DlPath simple_path = DlPath::MakeRoundRect(round_rect);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseUniformRoundRect) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPath path = MakeAlmostRoundRectPath(DlRect::MakeLTRB(100, 100, 300, 300),
                                        DlRoundingRadii::MakeRadius(30), false);

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  const RoundRect round_rect =
      RoundRect::MakeRectRadius(Rect::MakeLTRB(100, 100, 300, 300), 30);
  const DlPath simple_path = DlPath::MakeRoundRect(round_rect);
  DrawShadowAndCompareMeshes(builder, path, elevation, dpr, &simple_path);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseMultiRadiiRoundRect) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlRoundingRadii radii = DlRoundingRadii{
      .top_left = {80, 60},
      .top_right = {20, 25},
      .bottom_left = {60, 80},
      .bottom_right = {25, 20},
  };
  DlPath path = MakeAlmostRoundRectPath(DlRect::MakeLTRB(100, 100, 300, 300),
                                        radii, true);

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseMultiRadiiRoundRect) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlRoundingRadii radii = DlRoundingRadii{
      .top_left = {80, 60},
      .top_right = {20, 25},
      .bottom_left = {60, 80},
      .bottom_right = {25, 20},
  };
  DlPath path = MakeAlmostRoundRectPath(DlRect::MakeLTRB(100, 100, 300, 300),
                                        radii, false);

  // Path must be convex, but unrecognizable as a simple shape.
  ASSERT_TRUE(path.IsConvex());
  ASSERT_FALSE(path.IsRect());
  ASSERT_FALSE(path.IsOval());
  ASSERT_FALSE(path.IsRoundRect());

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

TEST_P(AiksTest, DrawShadowCanOptimizeClockwiseOctagon) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 125));
  path_builder.LineTo(DlPoint(125, 100));
  path_builder.LineTo(DlPoint(275, 100));
  path_builder.LineTo(DlPoint(300, 125));
  path_builder.LineTo(DlPoint(300, 275));
  path_builder.LineTo(DlPoint(275, 300));
  path_builder.LineTo(DlPoint(125, 300));
  path_builder.LineTo(DlPoint(100, 275));
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  DrawShadowAndCompareMeshes(builder, path, elevation, dpr);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, DrawShadowCanOptimizeCounterClockwiseOctagon) {
  DisplayListBuilder builder;
  builder.Clear(DlColor::kWhite());
  builder.Scale(GetContentScale().x, GetContentScale().y);
  Scalar dpr = std::max(GetContentScale().x, GetContentScale().y);
  Scalar elevation = 30.0f;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 125));
  path_builder.LineTo(DlPoint(100, 275));
  path_builder.LineTo(DlPoint(125, 300));
  path_builder.LineTo(DlPoint(275, 300));
  path_builder.LineTo(DlPoint(300, 275));
  path_builder.LineTo(DlPoint(300, 125));
  path_builder.LineTo(DlPoint(275, 100));
  path_builder.LineTo(DlPoint(125, 100));
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
