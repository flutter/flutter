// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path.h"

#include "gtest/gtest.h"

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/display_list/testing/dl_test_mock_path_receiver.h"
#include "flutter/third_party/skia/include/core/SkPath.h"
#include "flutter/third_party/skia/include/core/SkRRect.h"

namespace flutter {
namespace testing {

TEST(DisplayListPath, DefaultConstruction) {
  DlPath path;

  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());
  EXPECT_TRUE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
}

TEST(DisplayListPath, ConstructFromEmptySkiaPath) {
  SkPath sk_path;
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());

  EXPECT_TRUE(path.IsEmpty());
  EXPECT_FALSE(path.IsVolatile());

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
}

TEST(DisplayListPath, ConstructFromEmptyDlPathBuilder) {
  DlPathBuilder path_builder;
  DlPath path = path_builder.TakePath();

  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());

  EXPECT_TRUE(path.IsEmpty());
  EXPECT_FALSE(path.IsVolatile());

  EXPECT_EQ(path.GetBounds(), DlRect());
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
}

TEST(DisplayListPath, CopyConstruct) {
  SkPath sk_path = SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path1(sk_path);
  DlPath path2 = DlPath(path1);

  EXPECT_EQ(path2, path1);
  EXPECT_EQ(path2, DlPath(SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path2.GetSkPath(), SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path2.IsVolatile());

  EXPECT_EQ(path2.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path2.IsConvex());
  EXPECT_EQ(path2.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_FALSE(path2.IsRect(nullptr));
  EXPECT_FALSE(path2.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_TRUE(path2.IsOval(nullptr));
  EXPECT_FALSE(path2.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path2.IsRect(nullptr));
  EXPECT_FALSE(path2.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_TRUE(path2.IsOval(nullptr));
  EXPECT_FALSE(path2.IsRoundRect(nullptr));

  EXPECT_EQ(path2.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromVolatile) {
  SkPath sk_path;
  sk_path.setIsVolatile(true);
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath());
  EXPECT_EQ(path.GetSkPath(), SkPath());

  EXPECT_TRUE(path.IsEmpty());
  EXPECT_TRUE(path.IsVolatile());

  bool is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  is_closed = false;
  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsRect(nullptr, &is_closed));
  EXPECT_FALSE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect());
}

TEST(DisplayListPath, VolatileBecomesNonVolatile) {
  SkPath sk_path;
  sk_path.setIsVolatile(true);
  DlPath path(sk_path);

  EXPECT_TRUE(path.IsVolatile());

  for (int i = 0; i < 1000; i++) {
    // not specifying intent to render does not make it non-volatile
    path.GetSkPath();
  }
  EXPECT_TRUE(path.IsVolatile());

  for (uint32_t i = 0; i < DlPath::kMaxVolatileUses; i++) {
    // Expressing intent to render will only be volatile the first few times
    path.WillRenderSkPath();
    path.GetSkPath();
    EXPECT_TRUE(path.IsVolatile());
  }

  for (int i = 0; i < 1000; i++) {
    // further uses without expressing intent to render do not make it
    // non-volatile
    path.GetSkPath();
  }
  EXPECT_TRUE(path.IsVolatile());

  // One last time makes the path non-volatile
  path.WillRenderSkPath();
  path.GetSkPath();
  EXPECT_FALSE(path.IsVolatile());
}

TEST(DisplayListPath, MultipleVolatileCopiesBecomeNonVolatileTogether) {
  SkPath sk_path;
  sk_path.setIsVolatile(true);
  DlPath path(sk_path);
  const DlPath paths[4] = {
      path,
      path,
      path,
      path,
  };

  EXPECT_TRUE(path.IsVolatile());

  for (uint32_t i = 0; i < DlPath::kMaxVolatileUses; i++) {
    // Expressing intent to render will only be volatile the first few times
    paths[i].WillRenderSkPath();
    EXPECT_TRUE(path.IsVolatile());
    for (const auto& p : paths) {
      EXPECT_TRUE(p.IsVolatile());
    }
  }

  // One last time makes the path non-volatile
  paths[3].WillRenderSkPath();
  EXPECT_FALSE(path.IsVolatile());
  for (const auto& p : paths) {
    EXPECT_FALSE(p.IsVolatile());
  }
}

TEST(DisplayListPath, ConstructFromRect) {
  SkPath sk_path = SkPath::Rect(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath(SkPath::Rect(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path.GetSkPath(), SkPath::Rect(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_TRUE(path.IsRect(nullptr));
  DlRect dl_rect;
  EXPECT_TRUE(path.IsRect(&dl_rect, &is_closed));
  EXPECT_EQ(dl_rect, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderRect) {
  DlPathBuilder builder;
  builder.AddRect(DlRect::MakeLTRB(10, 10, 20, 20));
  DlPath path = builder.TakePath();

  {
    DlPathBuilder builder2;
    builder2.AddRect(DlRect::MakeLTRB(10, 10, 20, 20));
    EXPECT_EQ(path, builder2.TakePath());
  }

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  bool is_closed = false;
  EXPECT_TRUE(path.IsRect(nullptr));
  DlRect dl_rect;
  EXPECT_TRUE(path.IsRect(&dl_rect, &is_closed));
  EXPECT_EQ(dl_rect, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(is_closed);
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromOval) {
  SkPath sk_path = SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20));
  DlPath path(sk_path);

  EXPECT_EQ(path, DlPath(SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20))));
  EXPECT_EQ(path.GetSkPath(), SkPath::Oval(SkRect::MakeLTRB(10, 10, 20, 20)));

  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_TRUE(path.IsOval(nullptr));
  DlRect dl_bounds;
  EXPECT_TRUE(path.IsOval(&dl_bounds));
  EXPECT_EQ(dl_bounds, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderOval) {
  DlPathBuilder builder;
  builder.AddOval(DlRect::MakeLTRB(10, 10, 20, 20));
  DlPath path = builder.TakePath();

  {
    DlPathBuilder builder2;
    builder2.AddOval(DlRect::MakeLTRB(10, 10, 20, 20));
    EXPECT_EQ(path, builder2.TakePath());
  }

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_TRUE(path.IsOval(nullptr));
  DlRect dl_bounds;
  EXPECT_TRUE(path.IsOval(&dl_bounds));
  EXPECT_EQ(dl_bounds, DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromRRect) {
  SkPath sk_path = SkPath::RRect(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2);
  DlPath path(sk_path);

  EXPECT_EQ(path,
            DlPath(SkPath::RRect(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2)));
  EXPECT_EQ(path.GetSkPath(),
            SkPath::RRect(SkRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  DlRoundRect roundrect;
  EXPECT_TRUE(path.IsRoundRect(&roundrect));
  EXPECT_EQ(roundrect,
            DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderRoundRect) {
  DlPathBuilder builder;
  builder.AddRoundRect(
      DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));
  DlPath path = builder.TakePath();

  {
    DlPathBuilder builder2;
    builder2.AddRoundRect(
        DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));
    EXPECT_EQ(path, builder2.TakePath());
  }

  EXPECT_FALSE(path.GetSkPath().isEmpty());
  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  DlRoundRect roundrect;
  EXPECT_TRUE(path.IsRoundRect(&roundrect));
  EXPECT_EQ(roundrect,
            DlRoundRect::MakeRectXY(DlRect::MakeLTRB(10, 10, 20, 20), 1, 2));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromPath) {
  SkPath sk_path1;
  sk_path1.moveTo(10, 10);
  sk_path1.lineTo(20, 20);
  sk_path1.lineTo(20, 10);
  SkPath sk_path2;
  sk_path2.moveTo(10, 10);
  sk_path2.lineTo(20, 20);
  sk_path2.lineTo(20, 10);
  DlPath path(sk_path1);

  ASSERT_EQ(sk_path1, sk_path2);

  EXPECT_EQ(path, DlPath(sk_path2));
  EXPECT_EQ(path.GetSkPath(), sk_path2);

  EXPECT_FALSE(path.IsEmpty());

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
  EXPECT_TRUE(path.IsConvex());
  EXPECT_EQ(path.GetFillType(), DlPathFillType::kNonZero);

  EXPECT_FALSE(path.IsRect(nullptr));
  EXPECT_FALSE(path.IsOval(nullptr));
  EXPECT_FALSE(path.IsRoundRect(nullptr));

  EXPECT_EQ(path.GetBounds(), DlRect::MakeLTRB(10, 10, 20, 20));
}

TEST(DisplayListPath, ConstructFromDlPathBuilderEqualsConstructFromSkia) {
  DlPathBuilder path_builder;
  path_builder.SetFillType(DlPathFillType::kNonZero);
  path_builder.MoveTo({0, 0});
  path_builder.LineTo({100, 0});
  path_builder.LineTo({0, 100});
  path_builder.Close();

  SkPath sk_path;
  sk_path.setFillType(SkPathFillType::kWinding);
  sk_path.moveTo(0, 0);
  sk_path.lineTo(100, 0);
  sk_path.lineTo(0, 100);
  sk_path.close();

  EXPECT_EQ(path_builder.TakePath(), DlPath(sk_path));
}

TEST(DisplayListPath, IsLineFromSkPath) {
  SkPath sk_path;
  sk_path.moveTo(SkPoint::Make(0, 0));
  sk_path.lineTo(SkPoint::Make(100, 100));

  DlPath path = DlPath(sk_path);

  DlPoint start;
  DlPoint end;
  EXPECT_TRUE(path.IsLine(&start, &end));
  EXPECT_EQ(start, DlPoint::MakeXY(0, 0));
  EXPECT_EQ(end, DlPoint::MakeXY(100, 100));

  EXPECT_FALSE(DlPath(SkPath::Rect(SkRect::MakeLTRB(0, 0, 100, 100))).IsLine());
}

TEST(DisplayListPath, IsLineFromPathBuilder) {
  DlPathBuilder path_builder;
  path_builder.SetFillType(DlPathFillType::kNonZero);
  path_builder.MoveTo({0, 0});
  path_builder.LineTo({100, 0});
  DlPath path = path_builder.TakePath();

  DlPoint start;
  DlPoint end;
  EXPECT_TRUE(path.IsLine(&start, &end));
  EXPECT_EQ(start, DlPoint::MakeXY(0, 0));
  EXPECT_EQ(end, DlPoint::MakeXY(100, 0));

  {
    DlPathBuilder path_builder;
    path_builder.SetFillType(DlPathFillType::kNonZero);
    path_builder.MoveTo({0, 0});
    path_builder.LineTo({100, 0});
    path_builder.LineTo({100, 100});

    DlPath path = path_builder.TakePath();
    EXPECT_FALSE(path.IsLine());
  }
}

namespace {
using ::testing::AtMost;
using ::testing::Return;
}  // namespace

static void TestPathDispatchOneOfEachVerb(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(100, 200), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(101, 201)));
    EXPECT_CALL(mock_receiver, QuadTo(DlPoint(110, 202), DlPoint(102, 210)));
    EXPECT_CALL(mock_receiver,
                ConicTo(DlPoint(150, 240), DlPoint(250, 140), 0.5f))
        .WillOnce(Return(true));
    EXPECT_CALL(mock_receiver, CubicTo(DlPoint(300, 300), DlPoint(350, 300),
                                       DlPoint(300, 350)));
    // Closing LineTo added implicitly to return to first point
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(100, 200)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchSkiaPathOneOfEachVerb) {
  SkPath path;

  path.moveTo(100, 200);
  path.lineTo(101, 201);
  path.quadTo(110, 202, 102, 210);
  path.conicTo(150, 240, 250, 140, 0.5);
  path.cubicTo(300, 300, 350, 300, 300, 350);
  path.close();

  TestPathDispatchOneOfEachVerb(DlPath(path));
}

TEST(DisplayListPath, DispatchImpellerPathOneOfEachVerb) {
  DlPathBuilder path_builder;

  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.LineTo(DlPoint(101, 201));
  path_builder.QuadraticCurveTo(DlPoint(110, 202), DlPoint(102, 210));
  path_builder.ConicCurveTo(DlPoint(150, 240), DlPoint(250, 140), 0.5);
  path_builder.CubicCurveTo(DlPoint(300, 300), DlPoint(350, 300),
                            DlPoint(300, 350));
  path_builder.Close();

  TestPathDispatchOneOfEachVerb(path_builder.TakePath());
}

static void TestPathDispatchConicToQuads(
    const DlPath& path,
    DlScalar weight,
    const std::array<DlPoint, 4>& quad_points) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver,
                ConicTo(DlPoint(20, 10), DlPoint(20, 20), weight))
        .WillOnce(Return(false));
    EXPECT_CALL(mock_receiver,
                QuadTo(PointEq(quad_points[0]), PointEq(quad_points[1])));
    EXPECT_CALL(mock_receiver,
                QuadTo(PointEq(quad_points[2]), PointEq(quad_points[3])));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

static void TestSkiaPathDispatchConicToQuads(
    DlScalar weight,
    const std::array<DlPoint, 4>& quad_points) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.conicTo(20, 10, 20, 20, weight);

  TestPathDispatchConicToQuads(DlPath(sk_path), weight, quad_points);
}

static void TestImpellerPathDispatchConicToQuads(
    DlScalar weight,
    const std::array<DlPoint, 4>& quad_points) {
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(10, 10));
  path_builder.ConicCurveTo(DlPoint(20, 10), DlPoint(20, 20), weight);

  TestPathDispatchConicToQuads(path_builder.TakePath(), weight, quad_points);
}

TEST(DisplayListPath, DispatchSkiaPathConicToQuadsNearlyZero) {
  TestSkiaPathDispatchConicToQuads(kEhCloseEnough,
                                   {
                                       DlPoint(10.01f, 10.0f),
                                       DlPoint(15.005f, 14.995f),
                                       DlPoint(20.0f, 19.99f),
                                       DlPoint(20.0f, 20.0f),
                                   });
}
TEST(DisplayListPath, DispatchSkiaPathConicToQuadsHalf) {
  TestSkiaPathDispatchConicToQuads(0.5f, {
                                             DlPoint(13.3333f, 10.0f),
                                             DlPoint(16.6667f, 13.3333f),
                                             DlPoint(20.0f, 16.6667f),
                                             DlPoint(20.0f, 20.0f),
                                         });
}
TEST(DisplayListPath, DispatchSkiaPathConicToQuadsCircular) {
  TestSkiaPathDispatchConicToQuads(impeller::kSqrt2Over2,
                                   {
                                       DlPoint(14.1421f, 10.0f),
                                       DlPoint(17.0711f, 12.9289f),
                                       DlPoint(20.0f, 15.8579f),
                                       DlPoint(20.0f, 20.0f),
                                   });
}
TEST(DisplayListPath, DispatchSkiaPathConicToQuadsNearlyOne) {
  TestSkiaPathDispatchConicToQuads(1.0f - kEhCloseEnough,
                                   {
                                       DlPoint(14.9975f, 10.0f),
                                       DlPoint(17.4987f, 12.5013f),
                                       DlPoint(20.0f, 15.0025f),
                                       DlPoint(20.0f, 20.0f),
                                   });
}

TEST(DisplayListPath, DispatchImpellerPathConicToQuadsNearlyZero) {
  TestImpellerPathDispatchConicToQuads(kEhCloseEnough,
                                       {
                                           DlPoint(10.01f, 10.0f),
                                           DlPoint(15.005f, 14.995f),
                                           DlPoint(20.0f, 19.99f),
                                           DlPoint(20.0f, 20.0f),
                                       });
}
TEST(DisplayListPath, DispatchImpellerPathConicToQuadsHalf) {
  TestImpellerPathDispatchConicToQuads(0.5f, {
                                                 DlPoint(13.3333f, 10.0f),
                                                 DlPoint(16.6667f, 13.3333f),
                                                 DlPoint(20.0f, 16.6667f),
                                                 DlPoint(20.0f, 20.0f),
                                             });
}
TEST(DisplayListPath, DispatchImpellerPathConicToQuadsCircular) {
  TestImpellerPathDispatchConicToQuads(impeller::kSqrt2Over2,
                                       {
                                           DlPoint(14.1421f, 10.0f),
                                           DlPoint(17.0711f, 12.9289f),
                                           DlPoint(20.0f, 15.8579f),
                                           DlPoint(20.0f, 20.0f),
                                       });
}
TEST(DisplayListPath, DispatchImpellerPathConicToQuadsNearlyOne) {
  TestImpellerPathDispatchConicToQuads(1.0f - kEhCloseEnough,
                                       {
                                           DlPoint(14.9975f, 10.0f),
                                           DlPoint(17.4987f, 12.5013f),
                                           DlPoint(20.0f, 15.0025f),
                                           DlPoint(20.0f, 20.0f),
                                       });
}

static void TestPathDispatchUnclosedTriangle(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchUnclosedSkiaTriangle) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);

  TestPathDispatchUnclosedTriangle(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchUnclosedImpellerTriangle) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});

  TestPathDispatchUnclosedTriangle(path_builder.TakePath());
}

static void TestPathDispatchClosedTriangle(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 10)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchClosedSkiaTriangle) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.close();

  TestPathDispatchClosedTriangle(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchClosedPathBuilderTriangle) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.Close();

  TestPathDispatchClosedTriangle(path_builder.TakePath());
}

static void TestPathDispatchMixedCloseTriangles(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(110, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(120, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(110, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(110, 10)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(210, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(220, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(210, 20)));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchMixedCloseSkiaPath) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.moveTo(110, 10);
  sk_path.lineTo(120, 10);
  sk_path.lineTo(110, 20);
  sk_path.close();
  sk_path.moveTo(210, 10);
  sk_path.lineTo(220, 10);
  sk_path.lineTo(210, 20);

  TestPathDispatchMixedCloseTriangles(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchMixedCloseImpellerPath) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.MoveTo({110, 10});
  path_builder.LineTo({120, 10});
  path_builder.LineTo({110, 20});
  path_builder.Close();
  path_builder.MoveTo({210, 10});
  path_builder.LineTo({220, 10});
  path_builder.LineTo({210, 20});

  TestPathDispatchMixedCloseTriangles(path_builder.TakePath());
}

static void TestPathDispatchImplicitMoveAfterClose(const DlPath& path) {
  ::testing::StrictMock<DlPathReceiverMock> mock_receiver;

  {
    ::testing::InSequence sequence;

    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), true));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 20)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, 10)));
    EXPECT_CALL(mock_receiver, Close());
    EXPECT_CALL(mock_receiver, MoveTo(DlPoint(10, 10), false));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(-20, 10)));
    EXPECT_CALL(mock_receiver, LineTo(DlPoint(10, -20)));
    EXPECT_CALL(mock_receiver, PathEnd());
  }

  path.Dispatch(mock_receiver);
}

TEST(DisplayListPath, DispatchImplicitMoveAfterCloseSkiaPath) {
  SkPath sk_path;
  sk_path.moveTo(10, 10);
  sk_path.lineTo(20, 10);
  sk_path.lineTo(10, 20);
  sk_path.close();
  sk_path.lineTo(-20, 10);
  sk_path.lineTo(10, -20);

  TestPathDispatchImplicitMoveAfterClose(DlPath(sk_path));
}

TEST(DisplayListPath, DispatchImplicitMoveAfterClosePathBuilder) {
  DlPathBuilder path_builder;
  path_builder.MoveTo({10, 10});
  path_builder.LineTo({20, 10});
  path_builder.LineTo({10, 20});
  path_builder.Close();
  path_builder.LineTo({-20, 10});
  path_builder.LineTo({10, -20});

  TestPathDispatchImplicitMoveAfterClose(path_builder.TakePath());
}

#ifndef NDEBUG
// Tests that verify we don't try to use inverse path modes as they aren't
// supported by either Flutter public APIs or Impeller

TEST(DisplayListPath, CannotConstructFromSkiaInverseWinding) {
  SkPath sk_path;
  sk_path.setFillType(SkPathFillType::kInverseWinding);
  sk_path.moveTo(0, 0);
  sk_path.lineTo(100, 0);
  sk_path.lineTo(0, 100);
  sk_path.close();

  EXPECT_DEATH_IF_SUPPORTED(new DlPath(sk_path), "SkPathFillType_IsInverse");
}

TEST(DisplayListPath, CannotConstructFromSkiaInverseEvenOdd) {
  SkPath sk_path;
  sk_path.setFillType(SkPathFillType::kInverseEvenOdd);
  sk_path.moveTo(0, 0);
  sk_path.lineTo(100, 0);
  sk_path.lineTo(0, 100);
  sk_path.close();

  EXPECT_DEATH_IF_SUPPORTED(new DlPath(sk_path), "SkPathFillType_IsInverse");
}
#endif

}  // namespace testing
}  // namespace flutter
