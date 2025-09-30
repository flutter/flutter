// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_canvas.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DisplayListCanvas, GetShadowBoundsScaleTranslate) {
  DlMatrix matrix =
      DlMatrix::MakeTranslateScale({5.0f, 7.0f, 1.0f}, {10.0f, 15.0f, 7.0f});
  DlPath path = DlPath::MakeRectLTRB(100, 100, 200, 200);

  DlRect shadow_bounds =
      DlCanvas::ComputeShadowBounds(path, 5.0f, 2.0f, matrix);

  EXPECT_FLOAT_EQ(shadow_bounds.GetLeft(), 96.333336f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetTop(), 97.761909f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetRight(), 203.66667f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetBottom(), 205.09525f);
}

TEST(DisplayListCanvas, GetShadowBoundsScaleTranslateRotate) {
  DlMatrix matrix =
      DlMatrix::MakeTranslateScale({5.0f, 7.0f, 1.0f}, {10.0f, 15.0f, 7.0f});
  matrix = matrix * DlMatrix::MakeRotationZ(DlDegrees(45));
  DlPath path = DlPath::MakeRectLTRB(100, 100, 200, 200);

  DlRect shadow_bounds =
      DlCanvas::ComputeShadowBounds(path, 5.0f, 2.0f, matrix);

  EXPECT_FLOAT_EQ(shadow_bounds.GetLeft(), 97.343491f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetTop(), 97.343491f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetRight(), 204.67682f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetBottom(), 204.67682f);
}

TEST(DisplayListCanvas, GetShadowBoundsScaleTranslatePerspective) {
  DlMatrix matrix =
      DlMatrix::MakeTranslateScale({5.0f, 7.0f, 1.0f}, {10.0f, 15.0f, 7.0f});
  matrix.m[3] = 0.001f;
  DlPath path = DlPath::MakeRectLTRB(100, 100, 200, 200);

  DlRect shadow_bounds =
      DlCanvas::ComputeShadowBounds(path, 5.0f, 2.0f, matrix);

  EXPECT_FLOAT_EQ(shadow_bounds.GetLeft(), 96.535324f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetTop(), 90.253288f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetRight(), 204.15054f);
  EXPECT_FLOAT_EQ(shadow_bounds.GetBottom(), 223.3252f);
}

}  // namespace testing
}  // namespace flutter
