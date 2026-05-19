// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path_builder.h"

#include "gtest/gtest.h"

#include "flutter/display_list/testing/dl_test_mock_path_receiver.h"

namespace {
using ::testing::Return;
}  // namespace

namespace flutter {
namespace testing {

TEST(DisplayListPathBuilder, DefaultConstructor) {
  DlPathBuilder builder;
  DlPath path = builder.TakePath();

  EXPECT_TRUE(path.IsEmpty());
  EXPECT_TRUE(path.GetBounds().IsEmpty());
  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);
}

TEST(DisplayListPathBuilder, SetFillType) {
  DlPathBuilder builder;
  builder.SetFillType(DlPathFillType::kOdd);
  DlPath path = builder.TakePath();

  EXPECT_EQ(path.GetFillType(), DlPathFillType::kOdd);
}

TEST(DisplayListPathBuilder, CopyPathDoesNotResetPath) {
  DlPathBuilder builder;
  builder.SetFillType(DlPathFillType::kOdd);
  builder.MoveTo(DlPoint(10, 10));
  builder.LineTo(DlPoint(20, 10));
  builder.QuadraticCurveTo(DlPoint(20, 20), DlPoint(10, 20));
  DlPath before_path = builder.CopyPath();

  EXPECT_FALSE(before_path.IsEmpty());
  EXPECT_EQ(before_path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_NE(before_path, DlPath());
  EXPECT_EQ(before_path.GetFillType(), DlPathFillType::kOdd);

  DlPath after_path = builder.TakePath();

  EXPECT_FALSE(after_path.IsEmpty());
  EXPECT_EQ(after_path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_NE(after_path, DlPath());
  EXPECT_EQ(after_path, before_path);
  EXPECT_EQ(after_path.GetFillType(), DlPathFillType::kOdd);
}

TEST(DisplayListPathBuilder, TakePathResetsPath) {
  DlPathBuilder builder;
  builder.SetFillType(DlPathFillType::kOdd);
  builder.MoveTo(DlPoint(10, 10));
  builder.LineTo(DlPoint(20, 10));
  builder.QuadraticCurveTo(DlPoint(20, 20), DlPoint(10, 20));
  DlPath before_path = builder.TakePath();

  EXPECT_FALSE(before_path.IsEmpty());
  EXPECT_EQ(before_path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_NE(before_path, DlPath());
  EXPECT_EQ(before_path.GetFillType(), DlPathFillType::kOdd);

  DlPath after_path = builder.TakePath();

  EXPECT_TRUE(after_path.IsEmpty());
  EXPECT_TRUE(after_path.GetBounds().IsEmpty());
  EXPECT_EQ(after_path, DlPath());
  EXPECT_EQ(after_path.GetFillType(), DlPathFillType::kNonZero);
}

TEST(DisplayListPathBuilder, LineToInsertsMoveTo) {
  DlPathBuilder builder;
  builder.LineTo(DlPoint(10, 10));
  DlPath path = builder.TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(0, 0), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 10)));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, QuadToInsertsMoveTo) {
  DlPathBuilder builder;
  builder.QuadraticCurveTo(DlPoint(10, 10), DlPoint(10, 0));
  DlPath path = builder.TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(0, 0), false));
    EXPECT_CALL(mock_receiver, QuadTo(DlPoint(10, 10), DlPoint(10, 0)));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, ConicToInsertsMoveTo) {
  DlPathBuilder builder;
  builder.ConicCurveTo(DlPoint(10, 10), DlPoint(10, 0), 0.5f);
  DlPath path = builder.TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(0, 0), false));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 10), DlPoint(10, 0), 0.5f))
        .WillOnce(Return(true));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, CubicToInsertsMoveTo) {
  DlPathBuilder builder;
  builder.CubicCurveTo(DlPoint(10, 10), DlPoint(10, 0), DlPoint(0, 10));
  DlPath path = builder.TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(0, 0), false));
    EXPECT_CALL(mock_receiver,
                CubicTo(DlPoint(10, 10), DlPoint(10, 0), DlPoint(0, 10)));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, ConicWithNonPositiveWeightsInsertLineTo) {
  DlPathBuilder builder;
  builder.MoveTo(DlPoint(10, 10));
  builder.ConicCurveTo(DlPoint(20, 10), DlPoint(10, 20), -1.0f);
  builder.ConicCurveTo(DlPoint(20, 20), DlPoint(10, 30), 0.0f);
  builder.ConicCurveTo(DlPoint(20, 30), DlPoint(10, 40),
                       std::numeric_limits<DlScalar>::quiet_NaN());
  DlPath path = builder.TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 30)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 40)));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, ConicWithWeight1InsertsQuadTo) {
  DlPathBuilder builder;
  builder.MoveTo(DlPoint(10, 10));
  builder.ConicCurveTo(DlPoint(20, 10), DlPoint(10, 20), 1.0f);
  DlPath path = builder.TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, QuadTo(DlPoint(20, 10), DlPoint(10, 20)));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddRect) {
  auto path = DlPathBuilder{}  //
                  .AddRect(DlRect::MakeLTRB(10, 10, 20, 20))
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 10)));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddOval) {
  auto path = DlPathBuilder{}  //
                  .AddOval(DlRect::MakeLTRB(10, 10, 30, 20))
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    auto wt = impeller::kSqrt2Over2;
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(30, 15), true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(30, 20), DlPoint(20, 20), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 20), DlPoint(10, 15), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 10), DlPoint(20, 10), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(30, 10), DlPoint(30, 15), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddCircle) {
  auto path = DlPathBuilder{}  //
                  .AddCircle(DlPoint(15, 15), 5)
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    auto wt = impeller::kSqrt2Over2;
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(20, 15), true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(20, 20), DlPoint(15, 20), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 20), DlPoint(10, 15), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 10), DlPoint(15, 10), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(20, 10), DlPoint(20, 15), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddRoundRect) {
  auto bounds = DlRect::MakeLTRB(10, 10, 100, 100);
  auto radii = DlRoundingRadii{
      .top_left = DlSize(2, 12),
      .top_right = DlSize(3, 13),
      .bottom_left = DlSize(4, 14),
      .bottom_right = DlSize(5, 15),
  };
  auto path = DlPathBuilder{}  //
                  .AddRoundRect(DlRoundRect::MakeRectRadii(bounds, radii))
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    auto wt = impeller::kSqrt2Over2;
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 86), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 22)));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 10), DlPoint(12, 10), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(97, 10)));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(100, 10), DlPoint(100, 23), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(100, 85)));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(100, 100), DlPoint(95, 100), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(14, 100)));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 100), DlPoint(10, 86), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddRoundSuperellipse) {
  auto bounds = DlRect::MakeLTRB(10, 10, 100, 100);
  auto radii = DlRoundingRadii{
      .top_left = DlSize(2, 12),
      .top_right = DlSize(3, 13),
      .bottom_left = DlSize(4, 14),
      .bottom_right = DlSize(5, 15),
  };
  auto path = DlPathBuilder{}  //
                  .AddRoundSuperellipse(
                      DlRoundSuperellipse::MakeRectRadii(bounds, radii))
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(46, 10), true));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(97.3149f, 9.99998f)),
                                       PointEq(DlPoint(95.8867f, 9.99486f)),
                                       PointEq(DlPoint(97.1856f, 10.2338f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(97.9096f, 10.367f)),
                                       PointEq(DlPoint(98.5976f, 11.6373f)),
                                       PointEq(DlPoint(99.1213f, 13.8076f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(99.5784f, 15.7987f)),
                                       PointEq(DlPoint(99.8618f, 18.4156f)),
                                       PointEq(DlPoint(99.9232f, 21.2114f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(100.011f, 25.1954f)),
                                       PointEq(DlPoint(100.0f, 29.7897f)),
                                       PointEq(DlPoint(100.0f, 51.7857f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(100.0f, 77.1657f)),
                                       PointEq(DlPoint(100.018f, 82.4668f)),
                                       PointEq(DlPoint(99.872f, 87.0638f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(99.7697f, 90.2897f)),
                                       PointEq(DlPoint(99.2973f, 93.3092f)),
                                       PointEq(DlPoint(98.5355f, 95.6066f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(97.6834f, 98.0734f)),
                                       PointEq(DlPoint(96.5625f, 99.532f)),
                                       PointEq(DlPoint(95.3799f, 99.7131f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(93.4105f, 100.015f)),
                                       PointEq(DlPoint(93.4217f, 100.0f)),
                                       PointEq(DlPoint(50.0f, 100.0f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(15.2626f, 100.0f)),
                                       PointEq(DlPoint(15.2716f, 100.014f)),
                                       PointEq(DlPoint(13.6961f, 99.7323f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(12.75f, 99.5632f)),
                                       PointEq(DlPoint(11.8533f, 98.2018f)),
                                       PointEq(DlPoint(11.1716f, 95.8995f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.5569f, 93.7323f)),
                                       PointEq(DlPoint(10.1777f, 90.8822f)),
                                       PointEq(DlPoint(10.0993f, 87.8409f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(9.98623f, 83.4541f)),
                                       PointEq(DlPoint(10.0f, 78.5304f)),
                                       PointEq(DlPoint(10.0f, 51.5385f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.0f, 28.4025f)),
                                       PointEq(DlPoint(9.99311f, 24.1822f)),
                                       PointEq(DlPoint(10.0496f, 20.4221f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.0888f, 17.8153f)),
                                       PointEq(DlPoint(10.2785f, 15.3723f)),
                                       PointEq(DlPoint(10.5858f, 13.5147f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.9349f, 11.5114f)),
                                       PointEq(DlPoint(11.3936f, 10.3388f)),
                                       PointEq(DlPoint(11.8762f, 10.2158f))));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(12.7422f, 9.99527f)),
                                       PointEq(DlPoint(11.79f, 10.0f)),
                                       PointEq(DlPoint(46.0f, 10.0f))));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(46, 10)));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddArcNoCenter) {
  auto path = DlPathBuilder{}
                  .AddArc(DlRect::MakeLTRB(10, 10, 30, 20),  //
                          DlDegrees(90), DlDegrees(90), false)
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    auto wt = impeller::kSqrt2Over2;
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(20, 20), false));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 20), DlPoint(10, 15), wt))
        .WillOnce(Return(true));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, AddArcWithCenter) {
  auto path = DlPathBuilder{}
                  .AddArc(DlRect::MakeLTRB(10, 10, 30, 20),  //
                          DlDegrees(90), DlDegrees(90), true)
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    auto wt = impeller::kSqrt2Over2;
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(20, 15), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 20)));
    EXPECT_CALL(mock_receiver, ConicTo(DlPoint(10, 20), DlPoint(10, 15), wt))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 15)));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, SimpleUnclosedPath) {
  auto path = DlPathBuilder{}
                  .MoveTo({0, 0})
                  .LineTo({100, 100})
                  .QuadraticCurveTo({200, 200}, {300, 300})
                  .ConicCurveTo({200, 200}, {100, 100}, 0.75f)
                  .CubicCurveTo({300, 300}, {400, 400}, {500, 500})
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(0, 0), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(100, 100)));
    EXPECT_CALL(mock_receiver, QuadTo(DlPoint(200, 200), DlPoint(300, 300)));
    EXPECT_CALL(mock_receiver,
                ConicTo(DlPoint(200, 200), DlPoint(100, 100), 0.75f))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(DlPoint(300, 300), DlPoint(400, 400),
                                       DlPoint(500, 500)));
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, SimpleClosedPath) {
  auto path = DlPathBuilder{}
                  .MoveTo({0, 0})
                  .LineTo({100, 100})
                  .QuadraticCurveTo({200, 200}, {300, 300})
                  .ConicCurveTo({200, 200}, {100, 100}, 0.75f)
                  .CubicCurveTo({300, 300}, {400, 400}, {500, 500})
                  .Close()
                  .TakePath();

  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(0, 0), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(100, 100)));
    EXPECT_CALL(mock_receiver, QuadTo(DlPoint(200, 200), DlPoint(300, 300)));
    EXPECT_CALL(mock_receiver,
                ConicTo(DlPoint(200, 200), DlPoint(100, 100), 0.75f))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(DlPoint(300, 300), DlPoint(400, 400),
                                       DlPoint(500, 500)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(0, 0)));
    EXPECT_CALL(mock_receiver, Close());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPathBuilder, EvenOddAppendNonZeroStaysEvenOdd) {
  auto even_odd_path_builder = DlPathBuilder{}
                                   .SetFillType(DlPathFillType::kOdd)
                                   .MoveTo({0, 0})
                                   .LineTo({100, 0})
                                   .LineTo({0, 100})
                                   .Close();
  auto non_zero_path_builder = DlPathBuilder{}
                                   .SetFillType(DlPathFillType::kNonZero)
                                   .MoveTo({200, 200})
                                   .LineTo({300, 200})
                                   .LineTo({200, 300})
                                   .Close();

  even_odd_path_builder.AddPath(non_zero_path_builder.TakePath());
  auto path = even_odd_path_builder.TakePath();

  EXPECT_EQ(path.GetFillType(), DlPathFillType::kOdd);
}

TEST(DisplayListPathBuilder, NonZeroAppendEvenOddAppendStaysNonZero) {
  auto even_odd_path_builder = DlPathBuilder{}
                                   .SetFillType(DlPathFillType::kOdd)
                                   .MoveTo({0, 0})
                                   .LineTo({100, 0})
                                   .LineTo({0, 100})
                                   .Close();
  auto non_zero_path_builder = DlPathBuilder{}
                                   .SetFillType(DlPathFillType::kNonZero)
                                   .MoveTo({200, 200})
                                   .LineTo({300, 200})
                                   .LineTo({200, 300})
                                   .Close();

  non_zero_path_builder.AddPath(even_odd_path_builder.TakePath());
  auto path = non_zero_path_builder.TakePath();

  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);
}

}  // namespace testing
}  // namespace flutter
