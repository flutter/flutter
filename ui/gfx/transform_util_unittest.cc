// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/transform_util.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/point.h"
#include "ui/gfx/point3_f.h"
#include "ui/gfx/rect.h"

namespace gfx {
namespace {

TEST(TransformUtilTest, GetScaleTransform) {
  const Point kAnchor(20, 40);
  const float kScale = 0.5f;

  Transform scale = GetScaleTransform(kAnchor, kScale);

  const int kOffset = 10;
  for (int sign_x = -1; sign_x <= 1; ++sign_x) {
    for (int sign_y = -1; sign_y <= 1; ++sign_y) {
      Point test(kAnchor.x() + sign_x * kOffset,
                 kAnchor.y() + sign_y * kOffset);
      scale.TransformPoint(&test);

      EXPECT_EQ(Point(kAnchor.x() + sign_x * kOffset * kScale,
                      kAnchor.y() + sign_y * kOffset * kScale),
                test);
    }
  }
}

TEST(TransformUtilTest, SnapRotation) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;
  transform.RotateAboutZAxis(89.99);

  Rect viewport(1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_TRUE(snapped) << "Viewport should snap for this rotation.";
}

TEST(TransformUtilTest, SnapRotationDistantViewport) {
  const int kOffset = 5000;
  Transform result(Transform::kSkipInitialization);
  Transform transform;

  transform.RotateAboutZAxis(89.99);

  Rect viewport(kOffset, kOffset, 1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_FALSE(snapped) << "Distant viewport shouldn't snap by more than 1px.";
}

TEST(TransformUtilTest, NoSnapRotation) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;
  const int kOffset = 5000;

  transform.RotateAboutZAxis(89.9);

  Rect viewport(kOffset, kOffset, 1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_FALSE(snapped) << "Viewport should not snap for this rotation.";
}

// Translations should always be snappable, the most we would move is 0.5
// pixels towards either direction to the nearest value in each component.
TEST(TransformUtilTest, SnapTranslation) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;

  transform.Translate3d(
      SkDoubleToMScalar(1.01), SkDoubleToMScalar(1.99), SkDoubleToMScalar(3.0));

  Rect viewport(1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_TRUE(snapped) << "Viewport should snap for this translation.";
}

TEST(TransformUtilTest, SnapTranslationDistantViewport) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;
  const int kOffset = 5000;

  transform.Translate3d(
      SkDoubleToMScalar(1.01), SkDoubleToMScalar(1.99), SkDoubleToMScalar(3.0));

  Rect viewport(kOffset, kOffset, 1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_TRUE(snapped)
      << "Distant viewport should still snap by less than 1px.";
}

TEST(TransformUtilTest, SnapScale) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;

  transform.Scale3d(SkDoubleToMScalar(5.0),
                    SkDoubleToMScalar(2.00001),
                    SkDoubleToMScalar(1.0));
  Rect viewport(1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_TRUE(snapped) << "Viewport should snap for this scaling.";
}

TEST(TransformUtilTest, NoSnapScale) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;

  transform.Scale3d(
    SkDoubleToMScalar(5.0), SkDoubleToMScalar(2.1), SkDoubleToMScalar(1.0));
  Rect viewport(1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);

  EXPECT_FALSE(snapped) << "Viewport shouldn't snap for this scaling.";
}

TEST(TransformUtilTest, SnapCompositeTransform) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;

  transform.Translate3d(SkDoubleToMScalar(30.5), SkDoubleToMScalar(20.0),
                        SkDoubleToMScalar(10.1));
  transform.RotateAboutZAxis(89.99);
  transform.Scale3d(SkDoubleToMScalar(1.0),
                    SkDoubleToMScalar(3.00001),
                    SkDoubleToMScalar(2.0));

  Rect viewport(1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);
  ASSERT_TRUE(snapped) << "Viewport should snap all components.";

  Point3F point;

  point = Point3F(viewport.origin());
  result.TransformPoint(&point);
  EXPECT_EQ(Point3F(31.f, 20.f, 10.f), point) << "Transformed origin";

  point = Point3F(viewport.top_right());
  result.TransformPoint(&point);
  EXPECT_EQ(Point3F(31.f, 1940.f, 10.f), point) << "Transformed top-right";

  point = Point3F(viewport.bottom_left());
  result.TransformPoint(&point);
  EXPECT_EQ(Point3F(-3569.f, 20.f, 10.f), point) << "Transformed bottom-left";

  point = Point3F(viewport.bottom_right());
  result.TransformPoint(&point);
  EXPECT_EQ(Point3F(-3569.f, 1940.f, 10.f), point)
      << "Transformed bottom-right";
}

TEST(TransformUtilTest, NoSnapSkewedCompositeTransform) {
  Transform result(Transform::kSkipInitialization);
  Transform transform;


  transform.RotateAboutZAxis(89.99);
  transform.Scale3d(SkDoubleToMScalar(1.0),
                    SkDoubleToMScalar(3.00001),
                    SkDoubleToMScalar(2.0));
  transform.Translate3d(SkDoubleToMScalar(30.5), SkDoubleToMScalar(20.0),
                        SkDoubleToMScalar(10.1));
  transform.SkewX(20.0);
  Rect viewport(1920, 1200);
  bool snapped = SnapTransform(&result, transform, viewport);
  EXPECT_FALSE(snapped) << "Skewed viewport should not snap.";
}

}  // namespace
}  // namespace gfx
