// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/line_contents.h"

#include <algorithm>

#include "impeller/geometry/geometry_asserts.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

namespace impeller {
namespace testing {

namespace {
float lookup(Scalar x) {
  return std::clamp(x, /*lo=*/0.f, /*hi=*/1.f);
}

// This mirrors the function in line.frag.
float CalculateLine(const LineVertexShader::PerVertexData& per_vertex,
                    Point position) {
  Vector3 pos = Vector3(position.x, position.y, 1.0);
  Scalar d[4] = {pos.Dot(per_vertex.e0), pos.Dot(per_vertex.e1),
                 pos.Dot(per_vertex.e2), pos.Dot(per_vertex.e3)};

  for (int i = 0; i < 4; ++i) {
    if (d[i] < 0.f) {
      return 0.0;
    }
  }

  return lookup(std::min(d[0], d[2])) * lookup(std::min(d[1], d[3]));
}
}  // namespace

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

TEST(LineContents, CalculatePerVertex) {
  LineVertexShader::PerVertexData per_vertex[4];
  auto geometry = std::make_unique<LineGeometry>(
      /*p0=*/Point{100, 100},  //
      /*p1=*/Point{200, 100},  //
      /*width=*/5.f,           //
      /*cap=*/Cap::kButt);
  Matrix transform;

  fml::StatusOr<LineContents::EffectiveLineParameters> status =
      LineContents::CalculatePerVertex(per_vertex, geometry.get(), transform);
  Scalar offset =
      (LineContents::kSampleRadius * 2.0 + geometry->GetWidth()) / 2.f;
  ASSERT_TRUE(status.ok());
  EXPECT_EQ(status.value().width, 5.f);
  EXPECT_EQ(status.value().radius, LineContents::kSampleRadius);
  EXPECT_POINT_NEAR(per_vertex[0].position,
                    Point(100 - LineContents::kSampleRadius, 100 + offset));
  EXPECT_POINT_NEAR(per_vertex[1].position,
                    Point(200 + LineContents::kSampleRadius, 100 + offset));
  EXPECT_POINT_NEAR(per_vertex[2].position,
                    Point(100 - LineContents::kSampleRadius, 100 - offset));
  EXPECT_POINT_NEAR(per_vertex[3].position,
                    Point(200 + LineContents::kSampleRadius, 100 - offset));

  for (int i = 1; i < 4; ++i) {
    EXPECT_VECTOR3_NEAR(per_vertex[0].e0, per_vertex[i].e0) << i;
    EXPECT_VECTOR3_NEAR(per_vertex[0].e1, per_vertex[i].e1) << i;
    EXPECT_VECTOR3_NEAR(per_vertex[0].e2, per_vertex[i].e2) << i;
    EXPECT_VECTOR3_NEAR(per_vertex[0].e3, per_vertex[i].e3) << i;
  }

  EXPECT_EQ(CalculateLine(per_vertex[0], Point(0, 0)), 0.f);
  EXPECT_NEAR(CalculateLine(per_vertex[0], Point(150, 100 + offset)), 0.f,
              kEhCloseEnough);
  EXPECT_NEAR(CalculateLine(per_vertex[0], Point(150, 100 + offset * 0.5)),
              0.5f, kEhCloseEnough);
  EXPECT_NEAR(CalculateLine(per_vertex[0], Point(150, 100)), 1.f,
              kEhCloseEnough);
}

TEST(LineContents, CreateCurveData) {
  std::vector<uint8_t> data = LineContents::CreateCurveData(/*width=*/31,
                                                            /*radius=*/1,
                                                            /*scale=*/1);
  EXPECT_EQ(data.size(), 32u);
  EXPECT_NEAR(data[0] / 255.f, 0.f, kEhCloseEnough);
  EXPECT_NEAR(data[1] / 255.f, 0.5f, 0.02);
  EXPECT_NEAR(data[2] / 255.f, 1.f, kEhCloseEnough);
  EXPECT_NEAR(data[3] / 255.f, 1.f, kEhCloseEnough);
}

TEST(LineContents, CreateCurveDataScaled) {
  std::vector<uint8_t> data = LineContents::CreateCurveData(/*width=*/15.5,
                                                            /*radius=*/1,
                                                            /*scale=*/2);
  EXPECT_EQ(data.size(), 32u);
  EXPECT_NEAR(data[0] / 255.f, 0.f, kEhCloseEnough);
  EXPECT_NEAR(data[1] / 255.f, 0.5f, 0.02);
  EXPECT_NEAR(data[2] / 255.f, 1.f, kEhCloseEnough);
  EXPECT_NEAR(data[3] / 255.f, 1.f, kEhCloseEnough);
}

// This scales the line to be less than 1 pixel.
TEST(LineContents, CalculatePerVertexLimit) {
  LineVertexShader::PerVertexData per_vertex[4];
  Scalar scale = 0.05;
  auto geometry = std::make_unique<LineGeometry>(
      /*p0=*/Point{100, 100},  //
      /*p1=*/Point{200, 100},  //
      /*width=*/10.f,          //
      /*cap=*/Cap::kButt);
  Matrix transform = Matrix::MakeTranslation({100, 100, 1.0}) *
                     Matrix::MakeScale({scale, scale, 1.0}) *
                     Matrix::MakeTranslation({-100, -100, 1.0});

  fml::StatusOr<LineContents::EffectiveLineParameters> status =
      LineContents::CalculatePerVertex(per_vertex, geometry.get(), transform);

  Scalar one_radius_size = std::max(LineContents::kSampleRadius / scale,
                                    LineContents::kSampleRadius);
  Scalar one_px_size = 1.f / scale;
  Scalar offset = one_px_size / 2.f + one_radius_size;
  ASSERT_TRUE(status.ok());
  EXPECT_NEAR(status.value().width, 20.f, kEhCloseEnough);
  EXPECT_NEAR(status.value().radius, one_px_size * LineContents::kSampleRadius,
              kEhCloseEnough);
  EXPECT_POINT_NEAR(per_vertex[0].position,
                    Point(100 - one_radius_size, 100 + offset));
  EXPECT_POINT_NEAR(per_vertex[1].position,
                    Point(200 + one_radius_size, 100 + offset));
  EXPECT_POINT_NEAR(per_vertex[2].position,
                    Point(100 - one_radius_size, 100 - offset));
  EXPECT_POINT_NEAR(per_vertex[3].position,
                    Point(200 + one_radius_size, 100 - offset));

  EXPECT_NEAR(CalculateLine(per_vertex[0], Point(150, 100)), 1.f,
              kEhCloseEnough);
  // EXPECT_NEAR(CalculateLine(per_vertex[0], Point(150, 100 +
  // one_px_size)), 1.f,
  //             kEhCloseEnough);
}

}  // namespace testing
}  // namespace impeller
