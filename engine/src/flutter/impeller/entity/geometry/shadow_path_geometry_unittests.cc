// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/shadow_path_geometry.h"

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "gtest/gtest.h"

#include "flutter/third_party/skia/src/core/SkVerticesPriv.h"  // nogncheck
#include "flutter/third_party/skia/src/utils/SkShadowTessellator.h"  // nogncheck

#define SHOW_VERTICES false

namespace impeller {
namespace testing {

using namespace flutter;

namespace {

#if SHOW_VERTICES
static void ShowVertices(
    const std::string& label,
    const std::shared_ptr<ShadowVertices>& shadow_vertices) {
  auto vertices = shadow_vertices->GetVertices();
  auto alphas = shadow_vertices->GetGaussians();
  auto indices = shadow_vertices->GetIndices();
  FML_LOG(ERROR) << label << "[" << indices.size() / 3 << "] = {";
  for (size_t i = 0u; i < indices.size(); i += 3) {
    // clang-format off
    FML_LOG(ERROR)
        << "  (" << vertices[indices[i + 0]] << ", " << alphas[indices[i + 0]] << "), "
        << "  (" << vertices[indices[i + 1]] << ", " << alphas[indices[i + 1]] << "), "
        << "  (" << vertices[indices[i + 2]] << ", " << alphas[indices[i + 2]] << ")";
    // clang-format on
  }
  FML_LOG(ERROR) << "}  // " << label;
}
#endif

static constexpr Scalar kEpsilonSquared =
    flutter::kEhCloseEnough * flutter::kEhCloseEnough;

static bool SimilarPoint(Point p1, Point p2) {
  return p1.GetDistanceSquared(p2) < kEpsilonSquared;
}

static bool SimilarPointPair(Point p1_1, Point p1_2, Point p2_1, Point p2_2) {
  if (SimilarPoint(p1_1, p2_1) && SimilarPoint(p1_2, p2_2)) {
    return true;
  }
  if (SimilarPoint(p1_1, p2_2) && SimilarPoint(p1_2, p2_1)) {
    return true;
  }
  return false;
}

static bool SimilarPointTrio(Point p1_1,
                             Point p1_2,
                             Point p1_3,  //
                             Point p2_1,
                             Point p2_2,
                             Point p2_3) {
  if (SimilarPoint(p1_1, p2_1) && SimilarPointPair(p1_2, p1_3, p2_2, p2_3)) {
    return true;
  }
  if (SimilarPoint(p1_1, p2_2) && SimilarPointPair(p1_2, p1_3, p2_1, p2_3)) {
    return true;
  }
  if (SimilarPoint(p1_1, p2_3) && SimilarPointPair(p1_2, p1_3, p2_1, p2_2)) {
    return true;
  }
  return false;
}

static size_t CountDuplicateVertices(
    const std::shared_ptr<ShadowVertices>& shadow_vertices) {
  size_t duplicate_vertices = 0u;
  auto vertices = shadow_vertices->GetVertices();
  size_t vertex_count = vertices.size();

  for (size_t i = 1u; i < vertex_count; i++) {
    Point& vertex = vertices[i];
    for (size_t j = 0u; j < i; j--) {
      if (SimilarPoint(vertex, vertices[j])) {
        duplicate_vertices++;
      }
    }
  }

  return duplicate_vertices;
}

static size_t CountDuplicateTriangles(
    const std::shared_ptr<ShadowVertices>& shadow_vertices) {
  size_t duplicate_triangles = 0u;
  auto vertices = shadow_vertices->GetVertices();
  auto indices = shadow_vertices->GetIndices();
  size_t index_count = indices.size();

  for (size_t i = 3u; i < index_count; i += 3) {
    Point& vertex_1_1 = vertices[indices[i + 0]];
    Point& vertex_1_2 = vertices[indices[i + 1]];
    Point& vertex_1_3 = vertices[indices[i + 2]];
    for (size_t j = 0; j < i; j += 3) {
      Point& vertex_2_1 = vertices[indices[j + 0]];
      Point& vertex_2_2 = vertices[indices[j + 1]];
      Point& vertex_2_3 = vertices[indices[j + 2]];
      if (SimilarPointTrio(vertex_1_1, vertex_1_2, vertex_1_3,  //
                           vertex_2_1, vertex_2_2, vertex_2_3)) {
        duplicate_triangles++;
      }
    }
  }

  return duplicate_triangles;
}

}  // namespace

TEST(ShadowPathGeometryTest, EmptyPathTest) {
  DlPathBuilder path_builder;
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_TRUE(shadow_vertices->IsEmpty());
}

TEST(ShadowPathGeometryTest, MoveToOnlyTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_TRUE(shadow_vertices->IsEmpty());
}

TEST(ShadowPathGeometryTest, OnePathSegmentTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(200, 100));
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_TRUE(shadow_vertices->IsEmpty());
}

TEST(ShadowPathGeometryTest, TwoColinearSegmentsTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(300, 100));
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_TRUE(shadow_vertices->IsEmpty());
}

TEST(ShadowPathGeometryTest, EmptyRectTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(200, 100));
  path_builder.LineTo(DlPoint(100, 100));
  path_builder.Close();
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_TRUE(shadow_vertices->IsEmpty());
}

TEST(ShadowPathGeometryTest, ClockwiseRectTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.Close();
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 34u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 108u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 34u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 34u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 108u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  EXPECT_EQ(CountDuplicateVertices(shadow_vertices), 0u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);

#if SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);

#if EXPORT_SKIA_SHADOW
  auto sk_shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVerticesSkia(path, height, matrix);
  ShowVertices("Skia Vertices", sk_shadow_vertices);
#endif
#endif
}

TEST(ShadowPathGeometryTest, CounterClockwiseRectTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.Close();
  DlPath path = path_builder.TakePath();
  Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 34u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 108u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 34u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 34u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 108u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  EXPECT_EQ(CountDuplicateVertices(shadow_vertices), 0u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);

#if SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, ScaledRectTest) {
  Tessellator tessellator;
  DlPath path = DlPath::MakeRect(DlRect::MakeLTRB(0, 0, 100, 80));
  Matrix matrix = Matrix::MakeScale({2, 3, 1});
  const Scalar height = 10.0f;

  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 34u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 108u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 34u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 34u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 108u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  EXPECT_EQ(CountDuplicateVertices(shadow_vertices), 0u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);

#if SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, EllipseTest) {
  Tessellator tessellator;
  DlPath path = DlPath::MakeOval(DlRect::MakeLTRB(0, 0, 100, 80));
  Matrix matrix;
  const Scalar height = 10.0f;

  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 122u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 480u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 122u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 122u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 480u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  EXPECT_EQ(CountDuplicateVertices(shadow_vertices), 0u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
}

TEST(ShadowPathGeometryTest, RoundRectTest) {
  Tessellator tessellator;
  DlPath path = DlPath::MakeRoundRectXY(DlRect::MakeLTRB(0, 0, 100, 80), 5, 4);
  Matrix matrix;
  const Scalar height = 10.0f;

  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 51u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 156u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 51u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 51u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 156u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  EXPECT_EQ(CountDuplicateVertices(shadow_vertices), 0u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
}

}  // namespace testing
}  // namespace impeller
