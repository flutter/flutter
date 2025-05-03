// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/path_source.h"

#include "gtest/gtest.h"

#include "flutter/display_list/testing/dl_test_mock_path_receiver.h"
#include "flutter/testing/testing.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/round_rect.h"
#include "impeller/geometry/round_superellipse.h"

namespace impeller {
namespace testing {

using DlPathReceiverMock = flutter::testing::DlPathReceiverMock;

TEST(PathSourceTest, RectSourceTest) {
  Rect rect = Rect::MakeLTRB(10, 15, 20, 30);
  RectPathSource source(rect);

  EXPECT_TRUE(source.IsConvex());
  EXPECT_EQ(source.GetFillType(), FillType::kNonZero);
  EXPECT_EQ(source.GetBounds(), Rect::MakeLTRB(10, 15, 20, 30));

  ::testing::StrictMock<DlPathReceiverMock> receiver;

  {
    ::testing::Sequence sequence;

    EXPECT_CALL(receiver, MoveTo(Point(10, 15), true));
    EXPECT_CALL(receiver, LineTo(Point(20, 15)));
    EXPECT_CALL(receiver, LineTo(Point(20, 30)));
    EXPECT_CALL(receiver, LineTo(Point(10, 30)));
    EXPECT_CALL(receiver, LineTo(Point(10, 15)));
    EXPECT_CALL(receiver, Close());
    EXPECT_CALL(receiver, PathEnd());
  }

  source.Dispatch(receiver);
}

TEST(PathSourceTest, EllipseSourceTest) {
  Rect rect = Rect::MakeLTRB(10, 15, 20, 30);
  EllipsePathSource source(rect);

  EXPECT_TRUE(source.IsConvex());
  EXPECT_EQ(source.GetFillType(), FillType::kNonZero);
  EXPECT_EQ(source.GetBounds(), Rect::MakeLTRB(10, 15, 20, 30));

  ::testing::StrictMock<DlPathReceiverMock> receiver;

  {
    ::testing::Sequence sequence;

    EXPECT_CALL(receiver, MoveTo(Point(10, 22.5), true));
    EXPECT_CALL(receiver, ConicTo(Point(10, 15), Point(15, 15), kSqrt2Over2));
    EXPECT_CALL(receiver, ConicTo(Point(20, 15), Point(20, 22.5), kSqrt2Over2));
    EXPECT_CALL(receiver, ConicTo(Point(20, 30), Point(15, 30), kSqrt2Over2));
    EXPECT_CALL(receiver, ConicTo(Point(10, 30), Point(10, 22.5), kSqrt2Over2));
    EXPECT_CALL(receiver, Close());
    EXPECT_CALL(receiver, PathEnd());
  }

  source.Dispatch(receiver);
}

TEST(PathSourceTest, RoundRectSourceTest) {
  Rect rect = Rect::MakeLTRB(10, 15, 40, 60);
  RoundingRadii radii = {
      .top_left = Size(1, 11),
      .top_right = Size(2, 12),
      .bottom_left = Size(4, 14),
      .bottom_right = Size(3, 13),
  };
  RoundRect round_rect = RoundRect::MakeRectRadii(rect, radii);
  RoundRectPathSource source(round_rect);

  EXPECT_TRUE(source.IsConvex());
  EXPECT_EQ(source.GetFillType(), FillType::kNonZero);
  EXPECT_EQ(source.GetBounds(), Rect::MakeLTRB(10, 15, 40, 60));

  ::testing::StrictMock<DlPathReceiverMock> receiver;

  {
    ::testing::Sequence sequence;

    EXPECT_CALL(receiver, MoveTo(Point(11, 15), true));
    EXPECT_CALL(receiver, LineTo(Point(38, 15)));
    EXPECT_CALL(receiver, ConicTo(Point(40, 15), Point(40, 27), kSqrt2Over2));
    EXPECT_CALL(receiver, LineTo(Point(40, 47)));
    EXPECT_CALL(receiver, ConicTo(Point(40, 60), Point(37, 60), kSqrt2Over2));
    EXPECT_CALL(receiver, LineTo(Point(14, 60)));
    EXPECT_CALL(receiver, ConicTo(Point(10, 60), Point(10, 46), kSqrt2Over2));
    EXPECT_CALL(receiver, LineTo(Point(10, 26)));
    EXPECT_CALL(receiver, ConicTo(Point(10, 15), Point(11, 15), kSqrt2Over2));
    EXPECT_CALL(receiver, Close());
    EXPECT_CALL(receiver, PathEnd());
  }

  source.Dispatch(receiver);
}

}  // namespace testing
}  // namespace impeller