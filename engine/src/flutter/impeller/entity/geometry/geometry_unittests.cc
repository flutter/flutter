// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/testing/mocks.h"

inline ::testing::AssertionResult SolidVerticesNear(
    std::vector<impeller::SolidFillVertexShader::PerVertexData> a,
    std::vector<impeller::SolidFillVertexShader::PerVertexData> b) {
  if (a.size() != b.size()) {
    return ::testing::AssertionFailure() << "Colors length does not match";
  }
  for (auto i = 0u; i < b.size(); i++) {
    if (!PointNear(a[i].position, b[i].position)) {
      return ::testing::AssertionFailure() << "Positions are not equal.";
    }
  }
  return ::testing::AssertionSuccess();
}

inline ::testing::AssertionResult TextureVerticesNear(
    std::vector<impeller::TextureFillVertexShader::PerVertexData> a,
    std::vector<impeller::TextureFillVertexShader::PerVertexData> b) {
  if (a.size() != b.size()) {
    return ::testing::AssertionFailure() << "Colors length does not match";
  }
  for (auto i = 0u; i < b.size(); i++) {
    if (!PointNear(a[i].position, b[i].position)) {
      return ::testing::AssertionFailure() << "Positions are not equal.";
    }
    if (!PointNear(a[i].texture_coords, b[i].texture_coords)) {
      return ::testing::AssertionFailure() << "Texture coords are not equal.";
    }
  }
  return ::testing::AssertionSuccess();
}

#define EXPECT_SOLID_VERTICES_NEAR(a, b) \
  EXPECT_PRED2(&::SolidVerticesNear, a, b)
#define EXPECT_TEXTURE_VERTICES_NEAR(a, b) \
  EXPECT_PRED2(&::TextureVerticesNear, a, b)

namespace impeller {

class ImpellerEntityUnitTestAccessor {
 public:
  static std::vector<SolidFillVertexShader::PerVertexData>
  GenerateSolidStrokeVertices(const Path::Polyline& polyline,
                              Scalar stroke_width,
                              Scalar miter_limit,
                              Join stroke_join,
                              Cap stroke_cap,
                              Scalar scale) {
    return StrokePathGeometry::GenerateSolidStrokeVertices(
        polyline, stroke_width, miter_limit, stroke_join, stroke_cap, scale);
  }

  static std::vector<TextureFillVertexShader::PerVertexData>
  GenerateSolidStrokeVerticesUV(const Path::Polyline& polyline,
                                Scalar stroke_width,
                                Scalar miter_limit,
                                Join stroke_join,
                                Cap stroke_cap,
                                Scalar scale,
                                Point texture_origin,
                                Size texture_size,
                                const Matrix& effect_transform) {
    return StrokePathGeometry::GenerateSolidStrokeVerticesUV(
        polyline, stroke_width, miter_limit, stroke_join, stroke_cap, scale,
        texture_origin, texture_size, effect_transform);
  }
};

namespace testing {

TEST(EntityGeometryTest, RectGeometryCoversArea) {
  auto geometry = Geometry::MakeRect(Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversArea) {
  auto path = PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath();
  auto geometry = Geometry::MakeFillPath(
      path, /* inner rect */ Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversAreaNoInnerRect) {
  auto path = PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath();
  auto geometry = Geometry::MakeFillPath(path);
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, LineGeometryCoverage) {
  {
    auto geometry = Geometry::MakeLine({10, 10}, {20, 10}, 2, Cap::kButt);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(10, 9, 20, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(10, 9, 20, 11)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {20, 10}, 2, Cap::kSquare);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 21, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 21, 11)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {10, 20}, 2, Cap::kButt);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 10, 11, 20));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 10, 11, 20)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {10, 20}, 2, Cap::kSquare);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 11, 21));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 11, 21)));
  }
}

TEST(EntityGeometryTest, RoundRectGeometryCoversArea) {
  auto geometry =
      Geometry::MakeRoundRect(Rect::MakeLTRB(0, 0, 100, 100), Size(20, 20));
  EXPECT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(15, 15, 85, 85)));
  EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(20, 20, 80, 80)));
  EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(30, 1, 70, 99)));
  EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 30, 99, 70)));
}

TEST(EntityGeometryTest, StrokePathGeometryTransformOfLine) {
  auto path =
      PathBuilder().AddLine(Point(100, 100), Point(200, 100)).TakePath();
  auto points = std::make_unique<std::vector<Point>>();
  auto polyline =
      path.CreatePolyline(1.0f, std::move(points),
                          [&points](Path::Polyline::PointBufferPtr reclaimed) {
                            points = std::move(reclaimed);
                          });

  auto vertices = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      polyline, 10.0f, 10.0f, Join::kBevel, Cap::kButt, 1.0);

  std::vector<SolidFillVertexShader::PerVertexData> expected = {
      {.position = Point(100.0f, 105.0f)},  //
      {.position = Point(100.0f, 95.0f)},   //
      {.position = Point(100.0f, 105.0f)},  //
      {.position = Point(100.0f, 95.0f)},   //
      {.position = Point(200.0f, 105.0f)},  //
      {.position = Point(200.0f, 95.0f)},   //
      {.position = Point(200.0f, 105.0f)},  //
      {.position = Point(200.0f, 95.0f)},   //
  };

  EXPECT_SOLID_VERTICES_NEAR(vertices, expected);

  {
    auto uv_vertices =
        ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVerticesUV(
            polyline, 10.0f, 10.0f, Join::kBevel, Cap::kButt, 1.0,  //
            Point(50.0f, 40.0f), Size(20.0f, 40.0f), Matrix());
    // uvx = (x - 50) / 20
    // uvy = (y - 40) / 40
    auto uv = [](const Point& p) {
      return Point((p.x - 50.0f) / 20.0f,  //
                   (p.y - 40.0f) / 40.0f);
    };
    std::vector<TextureFillVertexShader::PerVertexData> uv_expected;
    for (size_t i = 0; i < expected.size(); i++) {
      auto p = expected[i].position;
      uv_expected.push_back({.position = p, .texture_coords = uv(p)});
    }

    EXPECT_TEXTURE_VERTICES_NEAR(uv_vertices, uv_expected);
  }

  {
    auto uv_vertices =
        ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVerticesUV(
            polyline, 10.0f, 10.0f, Join::kBevel, Cap::kButt, 1.0,  //
            Point(50.0f, 40.0f), Size(20.0f, 40.0f),
            Matrix::MakeScale({8.0f, 4.0f, 1.0f}));
    // uvx = ((x * 8) - 50) / 20
    // uvy = ((y * 4) - 40) / 40
    auto uv = [](const Point& p) {
      return Point(((p.x * 8.0f) - 50.0f) / 20.0f,
                   ((p.y * 4.0f) - 40.0f) / 40.0f);
    };
    std::vector<TextureFillVertexShader::PerVertexData> uv_expected;
    for (size_t i = 0; i < expected.size(); i++) {
      auto p = expected[i].position;
      uv_expected.push_back({.position = p, .texture_coords = uv(p)});
    }

    EXPECT_TEXTURE_VERTICES_NEAR(uv_vertices, uv_expected);
  }

  {
    auto uv_vertices =
        ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVerticesUV(
            polyline, 10.0f, 10.0f, Join::kBevel, Cap::kButt, 1.0,  //
            Point(50.0f, 40.0f), Size(20.0f, 40.0f),
            Matrix::MakeTranslation({8.0f, 4.0f}));
    // uvx = ((x + 8) - 50) / 20
    // uvy = ((y + 4) - 40) / 40
    auto uv = [](const Point& p) {
      return Point(((p.x + 8.0f) - 50.0f) / 20.0f,
                   ((p.y + 4.0f) - 40.0f) / 40.0f);
    };
    std::vector<TextureFillVertexShader::PerVertexData> uv_expected;
    for (size_t i = 0; i < expected.size(); i++) {
      auto p = expected[i].position;
      uv_expected.push_back({.position = p, .texture_coords = uv(p)});
    }

    EXPECT_TEXTURE_VERTICES_NEAR(uv_vertices, uv_expected);
  }
}

TEST(EntityGeometryTest, GeometryResultHasReasonableDefaults) {
  GeometryResult result;
  EXPECT_EQ(result.type, PrimitiveType::kTriangleStrip);
  EXPECT_EQ(result.transform, Matrix());
  EXPECT_EQ(result.mode, GeometryResult::Mode::kNormal);
}

}  // namespace testing
}  // namespace impeller
