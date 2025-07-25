// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/skia/dl_sk_canvas.h"

#include "flutter/display_list/skia/dl_sk_conversions.h"
#include "flutter/third_party/skia/include/utils/SkShadowUtils.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

void TestShadowBounds(bool with_rotate, bool with_perspective) {
  const SkVector3 light_position = SkVector3::Make(0.0f, -1.0f, 1.0f);
  const DlScalar light_radius =
      DlCanvas::kShadowLightRadius / DlCanvas::kShadowLightHeight;

  DlPath dl_path = DlPath::MakeRectLTRB(100, 100, 200, 200);
  for (int dpr = 1; dpr <= 2; dpr++) {
    for (int elevation = 1; elevation <= 5; elevation++) {
      SkVector3 z_params = SkVector3::Make(0.0f, 0.0f, elevation * dpr);
      for (int i = 1; i <= 10; i++) {
        DlScalar xScale = static_cast<DlScalar>(i);
        for (int j = 1; j <= 10; j++) {
          DlScalar yScale = static_cast<DlScalar>(j);

          DlMatrix matrix = DlMatrix::MakeTranslateScale({xScale, yScale, 1.0f},
                                                         {10.0f, 15.0f, 7.0f});
          if (with_rotate) {
            matrix = matrix * DlMatrix::MakeRotationZ(DlDegrees(45));
          }
          if (with_perspective) {
            matrix.m[3] = 0.001f;
          }
          SkMatrix sk_matrix;
          ASSERT_TRUE(ToSk(&matrix, sk_matrix) != nullptr);
          SkMatrix sk_inverse = sk_matrix;
          ASSERT_TRUE(sk_matrix.invert(&sk_inverse));

          auto label = (std::stringstream()
                        << "Matrix: " << matrix << ", elevation = " << elevation
                        << ", dpr = " << dpr)
                           .str();

          DlRect dl_bounds =
              DlCanvas::ComputeShadowBounds(dl_path, elevation, dpr, matrix);
          SkRect sk_bounds;
          ASSERT_TRUE(SkShadowUtils::GetLocalBounds(
              sk_matrix, dl_path.GetSkPath(), z_params, light_position,
              light_radius, kDirectionalLight_ShadowFlag, &sk_bounds))
              << label;
          EXPECT_FLOAT_EQ(dl_bounds.GetLeft(), sk_bounds.fLeft) << label;
          EXPECT_FLOAT_EQ(dl_bounds.GetTop(), sk_bounds.fTop) << label;
          EXPECT_FLOAT_EQ(dl_bounds.GetRight(), sk_bounds.fRight) << label;
          EXPECT_FLOAT_EQ(dl_bounds.GetBottom(), sk_bounds.fBottom) << label;
        }
      }
    }
  }
}

}  // namespace

TEST(DlSkCanvas, ShadowBoundsCompatibilityTranslateScale) {
  TestShadowBounds(false, false);
}

TEST(DlSkCanvas, ShadowBoundsCompatibilityTranslateScaleRotate) {
  TestShadowBounds(true, false);
}

TEST(DlSkCanvas, ShadowBoundsCompatibilityTranslateScalePerspective) {
  TestShadowBounds(false, true);
}

}  // namespace testing
}  // namespace flutter
