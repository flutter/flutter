// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/logging.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(EmbeddedViewParams, GetBoundingRectAfterMutationsWithNoMutations) {
  MutatorsStack stack;
  DlMatrix matrix;

  EmbeddedViewParams params(matrix, DlSize(1, 1), stack);
  EXPECT_EQ(params.finalBoundingRect(), DlRect::MakeXYWH(0, 0, 1, 1));
}

TEST(EmbeddedViewParams, GetBoundingRectAfterMutationsWithScale) {
  MutatorsStack stack;
  DlMatrix matrix = DlMatrix::MakeScale({2, 2, 1});
  stack.PushTransform(matrix);

  EmbeddedViewParams params(matrix, DlSize(1, 1), stack);
  EXPECT_EQ(params.finalBoundingRect(), DlRect::MakeXYWH(0, 0, 2, 2));
}

TEST(EmbeddedViewParams, GetBoundingRectAfterMutationsWithTranslate) {
  MutatorsStack stack;
  DlMatrix matrix = DlMatrix::MakeTranslation({1, 1});
  stack.PushTransform(matrix);

  EmbeddedViewParams params(matrix, DlSize(1, 1), stack);
  EXPECT_EQ(params.finalBoundingRect(), DlRect::MakeXYWH(1, 1, 1, 1));
}

TEST(EmbeddedViewParams, GetBoundingRectAfterMutationsWithRotation90) {
  MutatorsStack stack;
  DlMatrix matrix = DlMatrix::MakeRotationZ(DlDegrees(90));
  stack.PushTransform(matrix);

  EmbeddedViewParams params(matrix, DlSize(1, 1), stack);
  EXPECT_EQ(params.finalBoundingRect(), DlRect::MakeXYWH(-1, 0, 1, 1));
}

TEST(EmbeddedViewParams, GetBoundingRectAfterMutationsWithRotation45) {
  MutatorsStack stack;
  DlMatrix matrix = DlMatrix::MakeRotationZ(DlDegrees(45));
  stack.PushTransform(matrix);

  EmbeddedViewParams params(matrix, DlSize(1, 1), stack);
  EXPECT_EQ(params.finalBoundingRect(),
            DlRect::MakeXYWH(-sqrt(2) / 2, 0, sqrt(2), sqrt(2)));
}

TEST(EmbeddedViewParams,
     GetBoundingRectAfterMutationsWithTranslateScaleAndRotation) {
  DlMatrix matrix = DlMatrix::MakeTranslation({2, 2}) *
                    DlMatrix::MakeScale({3, 3, 1}) *
                    DlMatrix::MakeRotationZ(DlDegrees(90));

  MutatorsStack stack;
  stack.PushTransform(matrix);

  EmbeddedViewParams params(matrix, DlSize(1, 1), stack);
  EXPECT_EQ(params.finalBoundingRect(), DlRect::MakeXYWH(-1, 2, 3, 3));
}

}  // namespace testing
}  // namespace flutter
