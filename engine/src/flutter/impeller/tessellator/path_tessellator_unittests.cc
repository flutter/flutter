// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/impeller/tessellator/path_tessellator.h"

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/display_list/geometry/dl_path_builder.h"

namespace impeller {
namespace testing {

class MockPathVertexWriter : public impeller::PathTessellator::VertexWriter {
 public:
  MOCK_METHOD(void, Write, (Point point), (override));
  MOCK_METHOD(void, EndContour, (), (override));
};

class MockSegmentReceiver : public impeller::PathTessellator::SegmentReceiver {
 public:
  MOCK_METHOD(void,
              BeginContour,
              (Point origin, bool will_be_closed),
              (override));
  MOCK_METHOD(void, RecordLine, (Point p1, Point p2), (override));
  MOCK_METHOD(void, RecordQuad, (Point p1, Point cp, Point p2), (override));
  MOCK_METHOD(void,
              RecordConic,
              (Point p1, Point cp, Point p2, Scalar weight),
              (override));
  MOCK_METHOD(void,
              RecordCubic,
              (Point p1, Point cp1, Point cp2, Point p2),
              (override));
  MOCK_METHOD(void, EndContour, (Point origin, bool with_close), (override));
};

TEST(PathTessellatorTest, EmptyPath) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 0u);
  EXPECT_EQ(contours, 0u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, EmptyPathMultipleMoveTo) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.MoveTo({10, 10});
  builder.MoveTo({20, 20});
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 0u);
  EXPECT_EQ(contours, 0u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, SimpleClosedPath) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({10, 10});
  builder.LineTo({0, 20});
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 10), Point(0, 20)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 20), Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 4u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    EXPECT_CALL(mock_writer, Write(Point(0, 20)));
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, SimpleUnclosedPath) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({10, 10});
  builder.LineTo({0, 20});
  // Close not really needed for filled paths
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/false));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 10), Point(0, 20)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 20), Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/false));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 4u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    EXPECT_CALL(mock_writer, Write(Point(0, 20)));
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, SimplePathTrailingMoveTo) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({10, 10});
  builder.LineTo({0, 20});
  builder.Close();
  builder.MoveTo({500, 100});
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 10), Point(0, 20)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 20), Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 4u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    EXPECT_CALL(mock_writer, Write(Point(0, 20)));
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, DegenerateSegmentsPath) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({0, 0});
  builder.LineTo({0, 0});
  builder.QuadraticCurveTo({0, 0}, {0, 0});
  builder.QuadraticCurveTo({0, 0}, {0, 0});
  builder.ConicCurveTo({0, 0}, {0, 0}, 12.0f);
  builder.ConicCurveTo({0, 0}, {0, 0}, 12.0f);
  builder.CubicCurveTo({0, 0}, {0, 0}, {0, 0});
  builder.CubicCurveTo({0, 0}, {0, 0}, {0, 0});
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 1u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, QuadToLineToOptimization) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  // CP == P1
  builder.QuadraticCurveTo({0, 0}, {10, 10});
  // CP == P2
  builder.QuadraticCurveTo({20, 10}, {20, 10});
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 10), Point(20, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(20, 10), Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 4u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    EXPECT_CALL(mock_writer, Write(Point(20, 10)));
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, ConicToLineToOptimization) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  // CP == P1
  builder.ConicCurveTo({0, 0}, {10, 10}, 2.0f);
  // CP == P2
  builder.ConicCurveTo({20, 10}, {20, 10}, 2.0f);
  // weight == 0
  builder.ConicCurveTo({20, 0}, {10, 0}, 0.0f);
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 10), Point(20, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(20, 10), Point(10, 0)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 0), Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 5u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    EXPECT_CALL(mock_writer, Write(Point(20, 10)));
    EXPECT_CALL(mock_writer, Write(Point(10, 0)));
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, ConicToQuadToOptimization) {
  // The conic below will simplify to this quad
  PathTessellator::Quad quad{{0, 0}, {10, 0}, {0, 10}};

  flutter::DlPathBuilder builder;
  builder.MoveTo(quad.p1);
  // weight == 1
  builder.ConicCurveTo(quad.cp, quad.p2, 1.0f);
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, BeginContour(quad.p1, /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordQuad(quad.p1, quad.cp, quad.p2));
    EXPECT_CALL(mock_receiver, RecordLine(quad.p2, quad.p1));
    EXPECT_CALL(mock_receiver, EndContour(quad.p1, /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 7u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(quad.p1));
    {
      EXPECT_CALL(mock_writer, Write(quad.Solve(1 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(2 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(3 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(4 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.p2));
    }
    EXPECT_CALL(mock_writer, Write(quad.p1));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, SimplePathMultipleMoveTo) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({500, 100});
  builder.MoveTo({0, 0});
  builder.LineTo({10, 10});
  builder.LineTo({0, 20});
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(10, 10), Point(0, 20)));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 20), Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 4u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    EXPECT_CALL(mock_writer, Write(Point(0, 20)));
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, ComplexPath) {
  PathTessellator::Quad quad{{10, 10}, {20, 20}, {20, 10}};
  PathTessellator::Conic conic{{20, 10}, {30, 20}, {30, 10}, 2.0f};
  PathTessellator::Cubic cubic{{30, 10}, {40, 20}, {40, 10}, {42, 15}};

  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({10, 10});
  builder.QuadraticCurveTo(quad.cp, quad.p2);
  builder.ConicCurveTo(conic.cp, conic.p2, conic.weight);
  builder.CubicCurveTo(cubic.cp1, cubic.cp2, cubic.p2);
  builder.Close();
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordQuad(quad.p1, quad.cp, quad.p2));
    EXPECT_CALL(mock_receiver,
                RecordConic(conic.p1, conic.cp, conic.p2, conic.weight));
    EXPECT_CALL(mock_receiver,
                RecordCubic(cubic.p1, cubic.cp1, cubic.cp2, cubic.p2));
    EXPECT_CALL(mock_receiver, RecordLine(cubic.p2, Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 25u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    {
      EXPECT_CALL(mock_writer, Write(quad.Solve(1 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(2 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(3 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(4 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.p2));
    }
    {
      EXPECT_CALL(mock_writer, Write(conic.Solve(1 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(2 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(3 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(4 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(5 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(6 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(7 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.p2));
    }
    {
      EXPECT_CALL(mock_writer, Write(cubic.Solve(1 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(2 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(3 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(4 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(5 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(6 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(7 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(8 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.p2));
    }
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, ComplexPathTrailingMoveTo) {
  PathTessellator::Quad quad{{10, 10}, {20, 20}, {20, 10}};
  PathTessellator::Conic conic{{20, 10}, {30, 20}, {30, 10}, 2.0f};
  PathTessellator::Cubic cubic{{30, 10}, {40, 20}, {40, 10}, {42, 15}};

  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({10, 10});
  builder.QuadraticCurveTo(quad.cp, quad.p2);
  builder.ConicCurveTo(conic.cp, conic.p2, conic.weight);
  builder.CubicCurveTo(cubic.cp1, cubic.cp2, cubic.p2);
  builder.Close();
  builder.MoveTo({500, 100});
  flutter::DlPath path = builder.TakePath();

  ::testing::StrictMock<MockSegmentReceiver> mock_receiver;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver,
                BeginContour(Point(0, 0), /*will_be_closed=*/true));
    EXPECT_CALL(mock_receiver, RecordLine(Point(0, 0), Point(10, 10)));
    EXPECT_CALL(mock_receiver, RecordQuad(quad.p1, quad.cp, quad.p2));
    EXPECT_CALL(mock_receiver,
                RecordConic(conic.p1, conic.cp, conic.p2, conic.weight));
    EXPECT_CALL(mock_receiver,
                RecordCubic(cubic.p1, cubic.cp1, cubic.cp2, cubic.p2));
    EXPECT_CALL(mock_receiver, RecordLine(cubic.p2, Point(0, 0)));
    EXPECT_CALL(mock_receiver, EndContour(Point(0, 0), /*with_close=*/true));
  }
  PathTessellator::PathToFilledSegments(path, mock_receiver);

  auto [points, contours] = PathTessellator::CountFillStorage(path, 1.0f);
  EXPECT_EQ(points, 25u);
  EXPECT_EQ(contours, 1u);

  ::testing::StrictMock<MockPathVertexWriter> mock_writer;
  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, Write(Point(10, 10)));
    {
      EXPECT_CALL(mock_writer, Write(quad.Solve(1 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(2 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(3 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.Solve(4 / 5.0f)));
      EXPECT_CALL(mock_writer, Write(quad.p2));
    }
    {
      EXPECT_CALL(mock_writer, Write(conic.Solve(1 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(2 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(3 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(4 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(5 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(6 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.Solve(7 / 8.0f)));
      EXPECT_CALL(mock_writer, Write(conic.p2));
    }
    {
      EXPECT_CALL(mock_writer, Write(cubic.Solve(1 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(2 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(3 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(4 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(5 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(6 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(7 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.Solve(8 / 9.0f)));
      EXPECT_CALL(mock_writer, Write(cubic.p2));
    }
    EXPECT_CALL(mock_writer, Write(Point(0, 0)));
    EXPECT_CALL(mock_writer, EndContour());
  }
  PathTessellator::PathToFilledVertices(path, mock_writer, 1.0f);
}

TEST(PathTessellatorTest, LinearQuadToPointCount) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({316.3, 121.5});
  builder.QuadraticCurveTo({316.4, 121.5}, {316.5, 121.5});
  builder.Close();
  auto path = builder.TakePath();

  auto [points, contours] = PathTessellator::CountFillStorage(path, 2.0f);
  EXPECT_EQ(points, 3u);
  EXPECT_EQ(contours, 1u);
}

TEST(PathTessellatorTest, LinearConicToPointCount) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({316.3, 121.5});
  builder.ConicCurveTo({316.4, 121.5}, {316.5, 121.5}, 2.0f);
  builder.Close();
  auto path = builder.TakePath();

  auto [points, contours] = PathTessellator::CountFillStorage(path, 2.0f);
  EXPECT_EQ(points, 3u);
  EXPECT_EQ(contours, 1u);
}

TEST(PathTessellatorTest, LinearCubicToPointCount) {
  flutter::DlPathBuilder builder;
  builder.MoveTo({316.3, 121.5});
  builder.CubicCurveTo({316.4, 121.5}, {316.5, 121.5}, {316.6, 121.5});
  builder.Close();
  auto path = builder.TakePath();

  auto [points, contours] = PathTessellator::CountFillStorage(path, 2.0f);
  EXPECT_EQ(points, 3u);
  EXPECT_EQ(contours, 1u);
}

}  // namespace testing
}  // namespace impeller
