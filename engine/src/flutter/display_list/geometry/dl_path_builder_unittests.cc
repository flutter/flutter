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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
    EXPECT_CALL(mock_receiver, PathEnd());
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
