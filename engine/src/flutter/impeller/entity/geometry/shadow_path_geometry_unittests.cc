// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/shadow_path_geometry.h"

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "gtest/gtest.h"

#include "flutter/third_party/skia/src/core/SkVerticesPriv.h"  // nogncheck
#include "flutter/third_party/skia/src/utils/SkShadowTessellator.h"  // nogncheck

#define SHADOW_UNITTEST_SHOW_VERTICES false

namespace impeller {
namespace testing {

using flutter::DlPath;
using flutter::DlPathBuilder;
using flutter::DlPoint;
using flutter::DlRect;

namespace {

#if SHADOW_UNITTEST_SHOW_VERTICES
void ShowVertices(const std::string& label,
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

constexpr Scalar kEpsilonSquared =
    flutter::kEhCloseEnough * flutter::kEhCloseEnough;

bool SimilarPoint(Point p1, Point p2) {
  return p1.GetDistanceSquared(p2) < kEpsilonSquared;
}

bool SimilarPointPair(std::array<Point, 2> pair1, std::array<Point, 2> pair2) {
  if (SimilarPoint(pair1[1], pair2[1]) && SimilarPoint(pair1[2], pair2[2])) {
    return true;
  }
  if (SimilarPoint(pair1[1], pair2[2]) && SimilarPoint(pair1[2], pair2[1])) {
    return true;
  }
  return false;
}

bool SimilarPointTrio(std::array<Point, 3> trio1, std::array<Point, 3> trio2) {
  if (SimilarPoint(trio1[1], trio2[1]) &&
      SimilarPointPair({trio1[2], trio1[3]}, {trio2[2], trio2[3]})) {
    return true;
  }
  if (SimilarPoint(trio1[1], trio2[2]) &&
      SimilarPointPair({trio1[2], trio1[3]}, {trio2[1], trio2[3]})) {
    return true;
  }
  if (SimilarPoint(trio1[1], trio2[3]) &&
      SimilarPointPair({trio1[2], trio1[3]}, {trio2[1], trio2[2]})) {
    return true;
  }
  return false;
}

size_t CountDuplicateVertices(
    const std::shared_ptr<ShadowVertices>& shadow_vertices) {
  size_t duplicate_vertices = 0u;
  auto vertices = shadow_vertices->GetVertices();
  size_t vertex_count = vertices.size();

  for (size_t i = 1u; i < vertex_count; i++) {
    Point& vertex = vertices[i];
    for (size_t j = 0u; j < i; j++) {
      if (SimilarPoint(vertex, vertices[j])) {
        duplicate_vertices++;
      }
    }
  }

  return duplicate_vertices;
}

size_t CountDuplicateTriangles(
    const std::shared_ptr<ShadowVertices>& shadow_vertices) {
  size_t duplicate_triangles = 0u;
  auto vertices = shadow_vertices->GetVertices();
  auto indices = shadow_vertices->GetIndices();
  size_t index_count = indices.size();

  for (size_t i = 3u; i < index_count; i += 3) {
    std::array trio1 = {
        vertices[indices[i + 0]],
        vertices[indices[i + 1]],
        vertices[indices[i + 2]],
    };
    for (size_t j = 0; j < i; j += 3) {
      std::array trio2 = {
          vertices[indices[j + 0]],
          vertices[indices[j + 1]],
          vertices[indices[j + 2]],
      };
      if (SimilarPointTrio(trio1, trio2)) {
        duplicate_triangles++;
      }
    }
  }

  return duplicate_triangles;
}

bool IsPointInsideTriangle(Point p, std::array<Point, 3> triangle) {
  if (SimilarPoint(p, triangle[0]) ||  //
      SimilarPoint(p, triangle[1]) ||  //
      SimilarPoint(p, triangle[2])) {
    return false;
  }
  Scalar direction = Point::Cross(p, triangle[0], triangle[1]);
  // All 3 cross products must be non-zero and have the same sign.
  return direction * Point::Cross(p, triangle[1], triangle[2]) > 0 &&
         direction * Point::Cross(p, triangle[2], triangle[0]) > 0;
};

// This test verifies a condition that doesn't invalidate the process
// per se, but we'd have to use overlap prevention to render the mesh
// if this test returned true. We've carefully planned our meshes to
// avoid that condition, though, so we're just making sure.
bool DoTrianglesOverlap(
    const std::shared_ptr<ShadowVertices>& shadow_vertices) {
  auto vertices = shadow_vertices->GetVertices();
  auto indices = shadow_vertices->GetIndices();
  size_t index_count = indices.size();
  size_t vertex_count = vertices.size();

  for (size_t i = 0u; i < index_count; i += 3) {
    std::array triangle = {
        vertices[indices[i + 0]],
        vertices[indices[i + 1]],
        vertices[indices[i + 2]],
    };
    // Rather than check each pair of triangles to see if any of their
    // vertices is inside the other, we just check the list of all vertices
    // to see if that vertex is inside any triangle in the mesh.
    for (size_t j = 0; j < vertex_count; j++) {
      if (IsPointInsideTriangle(vertices[j], triangle)) {
        FML_LOG(ERROR) << "Point " << vertices[j] << " inside triangle ["
                       << triangle[0] << ", "  //
                       << triangle[1] << ", "  //
                       << triangle[2] << "]";
        FML_LOG(ERROR) << "Point - corner[0] == " << vertices[j] - triangle[0];
        FML_LOG(ERROR) << "Point - corner[1] == " << vertices[j] - triangle[1];
        FML_LOG(ERROR) << "Point - corner[2] == " << vertices[j] - triangle[2];
        return true;
      }
    }
  }

  return false;
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

TEST(ShadowPathGeometryTest, GetAndTakeVertices) {
  DlPath path = DlPath::MakeRectLTRB(100, 100, 200, 200);
  const Scalar height = 10.0f;

  Tessellator tessellator;
  ShadowPathGeometry geometry(tessellator, {}, path, height);

  // Can call Get as many times as you want.
  for (int i = 0; i < 10; i++) {
    EXPECT_TRUE(geometry.GetShadowVertices());
  }

  // Can only call Take once.
  EXPECT_TRUE(geometry.TakeShadowVertices());

  // Further access wll then fail.
  EXPECT_FALSE(geometry.GetShadowVertices());
  EXPECT_FALSE(geometry.TakeShadowVertices());
}

TEST(ShadowPathGeometryTest, ClockwiseTriangleTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(200, 110));
  path_builder.LineTo(DlPoint(0, 110));
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
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 33u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 102u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 33u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 33u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 102u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  // There is another duplicate vertex from somewhere else not yet realized.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 2u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, CounterClockwiseTriangleTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(0, 110));
  path_builder.LineTo(DlPoint(200, 110));
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
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 33u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 102u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 33u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 33u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 102u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  // There is another duplicate vertex from somewhere else not yet realized.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 2u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, ClockwiseRectExtraColinearPointsTest) {
  // This path includes a colinear point to each edge of the rectangle
  // which should be trimmed out and ignored when generating the mesh
  // resulting in the same number of vertices and triangles as the mesh
  // above.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(50, 0));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(100, 40));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(50, 80));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(0, 40));
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, CounterClockwiseRectExtraColinearPointsTest) {
  // This path includes a colinear point to each edge of the rectangle
  // which should be trimmed out and ignored when generating the mesh
  // resulting in the same number of vertices and triangles as the mesh
  // above.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(0, 40));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(50, 80));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(100, 40));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(50, 0));
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, ClockwiseRectTrickyColinearPointsTest) {
  // This path includes a colinear point added to each edge of the rectangle
  // which seems to violate convexity, but is eliminated as not contributing
  // to the path. We should be able to process the path anyway.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(-10, 0));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(100, -10));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(110, 80));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(0, 90));
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, CounterClockwiseRectTrickyColinearPointsTest) {
  // This path includes a colinear point added to each edge of the rectangle
  // which seems to violate convexity, but is eliminated as not contributing
  // to the path. We should be able to process the path anyway.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(0, -10));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(-10, 80));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(100, 90));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(110, 0));
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, ClockwiseRectTrickyDupColinearPointsTest) {
  // This path includes a colinear point added to each edge of the rectangle
  // which seems to violate convexity, but is eliminated as not contributing
  // to the path. We should be able to process the path anyway.
  // It also includes multiple collinear points on the first and last points
  // that end up back where we started to make sure that in that case we
  // eliminate all of the collinear points and the duplicate, rather than
  // just the intermediate collinear points.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(-10, 0));
  path_builder.LineTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(100, -10));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(110, 80));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(0, 90));
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, CounterClockwiseRectTrickyDupColinearPointsTest) {
  // This path includes a colinear point added to each edge of the rectangle
  // which seems to violate convexity, but is eliminated as not contributing
  // to the path. We should be able to process the path anyway.
  // It also includes multiple collinear points on the first and last points
  // that end up back where we started to make sure that in that case we
  // eliminate all of the collinear points and the duplicate, rather than
  // just the intermediate collinear points.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(0, -10));
  path_builder.LineTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(-10, 80));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(100, 90));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(110, 0));
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, ClockwiseRectNearlyColinearPointsTest) {
  // This path includes a bunch of colinear points and one point that
  // is barely non-colinear but still convex. It should add exactly
  // one extra set of vertices to the mesh (3 points and 3 triangles)
  // compared to the regular rects.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(50, -0.065));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(100, 40));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(50, 80));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(0, 40));
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
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 37u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 120u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 37u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 37u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 120u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
  ShowVertices("Impeller Vertices", shadow_vertices);
#endif
}

TEST(ShadowPathGeometryTest, CounterClockwiseRectNearlyColinearPointsTest) {
  // This path includes a bunch of colinear points and one point that
  // is barely non-colinear but still convex. It should add exactly
  // one extra set of vertices to the mesh (3 points and 3 triangles)
  // compared to the regular rects.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(-0.065, 40));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(50, 80));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(100, 40));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(50, 0));
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
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 37u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 120u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 37u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 37u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 120u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));

#if SHADOW_UNITTEST_SHOW_VERTICES
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
  // We repeat the first and last vertex that is on the outer umbra.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 1u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));
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
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 55u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 168u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 55u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 55u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 168u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  // There is another duplicate vertex from somewhere else not yet realized.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 2u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));
}

TEST(ShadowPathGeometryTest, HourglassSelfIntersectingTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.Close();
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

TEST(ShadowPathGeometryTest, ReverseHourglassSelfIntersectingTest) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 0));
  path_builder.LineTo(DlPoint(100, 80));
  path_builder.LineTo(DlPoint(0, 80));
  path_builder.LineTo(DlPoint(100, 0));
  path_builder.Close();
  const DlPath path = path_builder.TakePath();
  const Matrix matrix;
  const Scalar height = 10.0f;

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

TEST(ShadowPathGeometryTest, InnerToOuterOverturningSpiralTest) {
  const Matrix matrix;
  const Scalar height = 10.0f;
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

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

TEST(ShadowPathGeometryTest, ReverseInnerToOuterOverturningSpiralTest) {
  const Matrix matrix;
  const Scalar height = 10.0f;
  int step_count = 20;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(300, 200));
  for (int i = 1; i < step_count * 2; i++) {
    Scalar angle = -(k2Pi * i) / step_count;
    Scalar radius = 80.0f + std::abs(i - step_count);
    path_builder.LineTo(DlPoint(200, 200) + DlPoint(std::cos(angle) * radius,
                                                    std::sin(angle) * radius));
  }
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

TEST(ShadowPathGeometryTest, OuterToInnerOverturningSpiralTest) {
  const Matrix matrix;
  const Scalar height = 10.0f;
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

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

TEST(ShadowPathGeometryTest, ReverseOuterToInnerOverturningSpiralTest) {
  const Matrix matrix;
  const Scalar height = 10.0f;
  int step_count = 20;

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(280, 200));
  for (int i = 1; i < step_count * 2; i++) {
    Scalar angle = -(k2Pi * i) / step_count;
    Scalar radius = 100.0f - std::abs(i - step_count);
    path_builder.LineTo(DlPoint(200, 200) + DlPoint(std::cos(angle) * radius,
                                                    std::sin(angle) * radius));
  }
  path_builder.Close();
  DlPath path = path_builder.TakePath();

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

TEST(ShadowPathGeometryTest, ClockwiseOctagonCollapsedUmbraPolygonTest) {
  const Matrix matrix = Matrix::MakeScale({2, 2, 1});
  const Scalar height = 100.0f;

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

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 87u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 267u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 87u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 87u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 267u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  // There are a couple additional duplicate vertices in this case.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 3u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));
}

TEST(ShadowPathGeometryTest, CounterClockwiseOctagonCollapsedUmbraPolygonTest) {
  const Matrix matrix = Matrix::MakeScale({2, 2, 1});
  const Scalar height = 100.0f;

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

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  ASSERT_NE(shadow_vertices, nullptr);
  EXPECT_FALSE(shadow_vertices->IsEmpty());
  EXPECT_EQ(shadow_vertices->GetVertexCount(), 88u);
  EXPECT_EQ(shadow_vertices->GetIndexCount(), 267u);
  EXPECT_EQ(shadow_vertices->GetVertices().size(), 88u);
  EXPECT_EQ(shadow_vertices->GetGaussians().size(), 88u);
  EXPECT_EQ(shadow_vertices->GetIndices().size(), 267u);
  EXPECT_EQ((shadow_vertices->GetIndices().size() % 3u), 0u);
  // We repeat the first and last vertex that is on the outer umbra.
  // There are a couple additional duplicate vertices in this case.
  EXPECT_LE(CountDuplicateVertices(shadow_vertices), 3u);
  EXPECT_EQ(CountDuplicateTriangles(shadow_vertices), 0u);
  EXPECT_FALSE(DoTrianglesOverlap(shadow_vertices));
}

TEST(ShadowPathGeometryTest, MultipleContoursTest) {
  const Matrix matrix;
  const Scalar height = 10.0f;

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

  Tessellator tessellator;
  std::shared_ptr<ShadowVertices> shadow_vertices =
      ShadowPathGeometry::MakeAmbientShadowVertices(tessellator, path, height,
                                                    matrix);

  EXPECT_EQ(shadow_vertices, nullptr);
}

}  // namespace testing
}  // namespace impeller
