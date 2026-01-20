// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path_builder.h"

#include "gtest/gtest.h"

#include "flutter/display_list/testing/dl_test_mock_path_receiver.h"

namespace {
using ::testing::Return;

MATCHER_P(ScalarEq, a, "") {
  *result_listener << "isn't equal to " << a;
  return abs(arg - a) <= impeller::kEhCloseEnough;
}
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

    // 1
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(94.8672, 9.99998)),
                                       PointEq(DlPoint(95.7708, 10.0493)),
                                       ScalarEq(3.63127851)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(96.6558, 10.0976)),
                                       PointEq(DlPoint(97.1856, 10.2338)),
                                       ScalarEq(1.22087204)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(97.9096f, 10.367f)),
                                       PointEq(DlPoint(98.5976, 11.6373)),
                                       PointEq(DlPoint(99.1213, 13.8076))));

    // 2
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(99.5784, 15.7987)),
                                       PointEq(DlPoint(99.8618, 18.4156)),
                                       PointEq(DlPoint(99.9232, 21.2114))));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(99.9636, 23.0102)),
                                       PointEq(DlPoint(99.9805, 25.6229)),
                                       ScalarEq(1.17059147)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver,
                ConicTo(PointEq(DlPoint(100, 28.6213)),
                        PointEq(DlPoint(100, 51.7857)), ScalarEq(2.12785244)))
        .WillOnce(Return(true));

    // 3
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(100, 78.514)),
                                       PointEq(DlPoint(99.9675, 81.9736)),
                                       ScalarEq(2.12785244)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(99.9393, 84.9882)),
                                       PointEq(DlPoint(99.872, 87.0638)),
                                       ScalarEq(1.17059147)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(99.7697, 90.2897)),
                                       PointEq(DlPoint(99.2973, 93.3092)),
                                       PointEq(DlPoint(98.5355, 95.6066))));

    // 4
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(97.6834, 98.0734)),
                                       PointEq(DlPoint(96.5625, 99.532)),
                                       PointEq(DlPoint(95.3799, 99.7131))));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(94.5196, 99.8799)),
                                       PointEq(DlPoint(93.1037, 99.9395)),
                                       ScalarEq(1.16898668)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver,
                ConicTo(PointEq(DlPoint(91.6668, 100)),
                        PointEq(DlPoint(50, 100)), ScalarEq(3.63127851)))
        .WillOnce(Return(true));

    // 5
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(16.6667, 100)),
                                       PointEq(DlPoint(15.5171, 99.9435)),
                                       ScalarEq(3.63127851)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(14.3843, 99.8879)),
                                       PointEq(DlPoint(13.6961, 99.7323)),
                                       ScalarEq(1.16898668)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(12.75, 99.5632)),
                                       PointEq(DlPoint(11.8533, 98.2018)),
                                       PointEq(DlPoint(11.1716, 95.8995))));

    // 6
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.5569, 93.7323)),
                                       PointEq(DlPoint(10.1777, 90.8822)),
                                       PointEq(DlPoint(10.0993, 87.8409))));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(10.0462, 85.8435)),
                                       PointEq(DlPoint(10.0244, 82.8947)),
                                       ScalarEq(1.2416352)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver,
                ConicTo(PointEq(DlPoint(10, 79.594)),
                        PointEq(DlPoint(10, 51.5385)), ScalarEq(1.77972043)))
        .WillOnce(Return(true));

    // 7
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(10, 27.4909)),
                                       PointEq(DlPoint(10.0122, 24.6616)),
                                       ScalarEq(1.77972043)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(10.0231, 22.1342)),
                                       PointEq(DlPoint(10.0496, 20.4221)),
                                       ScalarEq(1.2416352)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.0888, 17.8153)),
                                       PointEq(DlPoint(10.2785, 15.3723)),
                                       PointEq(DlPoint(10.5858, 13.5147))));

    // 8
    EXPECT_CALL(mock_receiver, CubicTo(PointEq(DlPoint(10.9349, 11.5114)),
                                       PointEq(DlPoint(11.3936, 10.3388)),
                                       PointEq(DlPoint(11.8762, 10.2158))));
    EXPECT_CALL(mock_receiver, ConicTo(PointEq(DlPoint(12.2295, 10.0901)),
                                       PointEq(DlPoint(12.8195, 10.0455)),
                                       ScalarEq(1.22087204)))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver,
                ConicTo(PointEq(DlPoint(13.4216, 10)), PointEq(DlPoint(46, 10)),
                        ScalarEq(3.63127851)))
        .WillOnce(Return(true));

    EXPECT_CALL(mock_receiver, LineTo(PointEq(DlPoint(46, 10))));
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
