// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/round_superellipse.h"
#include "flutter/impeller/geometry/round_superellipse_param.h"

#include "flutter/impeller/geometry/geometry_asserts.h"

#define CHECK_POINT_WITH_OFFSET(rr, p, outward_offset) \
  EXPECT_TRUE(rr.Contains(p));                         \
  EXPECT_FALSE(rr.Contains(p + outward_offset));

namespace impeller {

namespace {

// A `PathReceiver` that allows setting callbacks for each kind of path
// segments.
class SpyPathReceiver : public PathReceiver {
 public:
  // For now not all segment types are defined since they're not all used.
  using LineSegment = std::function<void(const Point&)>;
  using CubicSegment =
      std::function<void(const Point&, const Point&, const Point&)>;

  void SpyLineTo(LineSegment line_to) { line_to_ = std::move(line_to); }

  void SpyCubicTo(CubicSegment cubic_to) { cubic_to_ = std::move(cubic_to); }

  // |PathReceiver|
  void MoveTo(const Point& p2, bool will_be_closed) override {}
  // |PathReceiver|
  void LineTo(const Point& p2) override {
    if (line_to_) {
      line_to_(p2);
    }
  }
  // |PathReceiver|
  void QuadTo(const Point& cp, const Point& p2) override {}
  // |PathReceiver|
  void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) override {
    if (cubic_to_) {
      cubic_to_(cp1, cp2, p2);
    }
  }
  // |PathReceiver|
  void Close() override {}

 private:
  LineSegment line_to_;
  CubicSegment cubic_to_;
};

}  // namespace

namespace testing {

TEST(RoundSuperellipseTest, EmptyDeclaration) {
  RoundSuperellipse rse;

  EXPECT_TRUE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_TRUE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect());
  EXPECT_EQ(rse.GetBounds().GetLeft(), 0.0f);
  EXPECT_EQ(rse.GetBounds().GetTop(), 0.0f);
  EXPECT_EQ(rse.GetBounds().GetRight(), 0.0f);
  EXPECT_EQ(rse.GetBounds().GetBottom(), 0.0f);
  EXPECT_EQ(rse.GetRadii().top_left, Size());
  EXPECT_EQ(rse.GetRadii().top_right, Size());
  EXPECT_EQ(rse.GetRadii().bottom_left, Size());
  EXPECT_EQ(rse.GetRadii().bottom_right, Size());
  EXPECT_EQ(rse.GetRadii().top_left.width, 0.0f);
  EXPECT_EQ(rse.GetRadii().top_left.height, 0.0f);
  EXPECT_EQ(rse.GetRadii().top_right.width, 0.0f);
  EXPECT_EQ(rse.GetRadii().top_right.height, 0.0f);
  EXPECT_EQ(rse.GetRadii().bottom_left.width, 0.0f);
  EXPECT_EQ(rse.GetRadii().bottom_left.height, 0.0f);
  EXPECT_EQ(rse.GetRadii().bottom_right.width, 0.0f);
  EXPECT_EQ(rse.GetRadii().bottom_right.height, 0.0f);
}

TEST(RoundSuperellipseTest, DefaultConstructor) {
  RoundSuperellipse rse = RoundSuperellipse();

  EXPECT_TRUE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_TRUE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect());
  EXPECT_EQ(rse.GetRadii().top_left, Size());
  EXPECT_EQ(rse.GetRadii().top_right, Size());
  EXPECT_EQ(rse.GetRadii().bottom_left, Size());
  EXPECT_EQ(rse.GetRadii().bottom_right, Size());
}

TEST(RoundSuperellipseTest, EmptyRectConstruction) {
  RoundSuperellipse rse =
      RoundSuperellipse::MakeRect(Rect::MakeLTRB(20.0f, 20.0f, 20.0f, 20.0f));

  EXPECT_TRUE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_TRUE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(20.0f, 20.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size());
  EXPECT_EQ(rse.GetRadii().top_right, Size());
  EXPECT_EQ(rse.GetRadii().bottom_left, Size());
  EXPECT_EQ(rse.GetRadii().bottom_right, Size());
}

TEST(RoundSuperellipseTest, RectConstructor) {
  RoundSuperellipse rse =
      RoundSuperellipse::MakeRect(Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_TRUE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size());
  EXPECT_EQ(rse.GetRadii().top_right, Size());
  EXPECT_EQ(rse.GetRadii().bottom_left, Size());
  EXPECT_EQ(rse.GetRadii().bottom_right, Size());
}

TEST(RoundSuperellipseTest, InvertedRectConstruction) {
  RoundSuperellipse rse =
      RoundSuperellipse::MakeRect(Rect::MakeLTRB(20.0f, 20.0f, 10.0f, 10.0f));

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_TRUE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size());
  EXPECT_EQ(rse.GetRadii().top_right, Size());
  EXPECT_EQ(rse.GetRadii().bottom_left, Size());
  EXPECT_EQ(rse.GetRadii().bottom_right, Size());
}

TEST(RoundSuperellipseTest, EmptyOvalConstruction) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectXY(
      Rect::MakeLTRB(20.0f, 20.0f, 20.0f, 20.0f), 10.0f, 10.0f);

  EXPECT_TRUE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_TRUE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(20.0f, 20.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size());
  EXPECT_EQ(rse.GetRadii().top_right, Size());
  EXPECT_EQ(rse.GetRadii().bottom_left, Size());
  EXPECT_EQ(rse.GetRadii().bottom_right, Size());
}

TEST(RoundSuperellipseTest, OvalConstructor) {
  RoundSuperellipse rse =
      RoundSuperellipse::MakeOval(Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_TRUE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(5.0f, 5.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(5.0f, 5.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(5.0f, 5.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(5.0f, 5.0f));
}

TEST(RoundSuperellipseTest, InvertedOvalConstruction) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectXY(
      Rect::MakeLTRB(20.0f, 20.0f, 10.0f, 10.0f), 10.0f, 10.0f);

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_TRUE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(5.0f, 5.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(5.0f, 5.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(5.0f, 5.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(5.0f, 5.0f));
}

TEST(RoundSuperellipseTest, RectRadiusConstructor) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadius(
      Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f), 2.0f);

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(2.0f, 2.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(2.0f, 2.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(2.0f, 2.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(2.0f, 2.0f));
}

TEST(RoundSuperellipseTest, RectXYConstructor) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectXY(
      Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f), 2.0f, 3.0f);

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(2.0f, 3.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(2.0f, 3.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(2.0f, 3.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(2.0f, 3.0f));
}

TEST(RoundSuperellipseTest, RectSizeConstructor) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectXY(
      Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f), Size(2.0f, 3.0f));

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(2.0f, 3.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(2.0f, 3.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(2.0f, 3.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(2.0f, 3.0f));
}

TEST(RoundSuperellipseTest, RectRadiiConstructor) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f),
      {
          .top_left = Size(1.0, 1.5),
          .top_right = Size(2.0, 2.5f),
          .bottom_left = Size(3.0, 3.5f),
          .bottom_right = Size(4.0, 4.5f),
      });

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 20.0f, 20.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(1.0f, 1.5f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(2.0f, 2.5f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(3.0f, 3.5f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(4.0f, 4.5f));
}

TEST(RoundSuperellipseTest, RectRadiiOverflowWidthConstructor) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 6.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  // Largest sum of paired radii widths is the bottom edge which sums to 12
  // Rect is only 6 wide so all radii are scaled by half
  // Rect is 30 tall so no scaling should happen due to radii heights

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 16.0f, 40.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(0.5f, 1.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(1.5f, 2.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(2.5f, 3.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(3.5f, 4.0f));
}

TEST(RoundSuperellipseTest, RectRadiiOverflowHeightConstructor) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 6.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  // Largest sum of paired radii heights is the right edge which sums to 12
  // Rect is only 6 tall so all radii are scaled by half
  // Rect is 30 wide so no scaling should happen due to radii widths

  EXPECT_FALSE(rse.IsEmpty());
  EXPECT_FALSE(rse.IsRect());
  EXPECT_FALSE(rse.IsOval());
  EXPECT_TRUE(rse.IsFinite());
  EXPECT_FALSE(rse.GetBounds().IsEmpty());
  EXPECT_EQ(rse.GetBounds(), Rect::MakeLTRB(10.0f, 10.0f, 40.0f, 16.0f));
  EXPECT_EQ(rse.GetRadii().top_left, Size(0.5f, 1.0f));
  EXPECT_EQ(rse.GetRadii().top_right, Size(1.5f, 2.0f));
  EXPECT_EQ(rse.GetRadii().bottom_left, Size(2.5f, 3.0f));
  EXPECT_EQ(rse.GetRadii().bottom_right, Size(3.5f, 4.0f));
}

TEST(RoundSuperellipseTest, Shift) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse shifted = rse.Shift(5.0, 6.0);

  EXPECT_FALSE(shifted.IsEmpty());
  EXPECT_FALSE(shifted.IsRect());
  EXPECT_FALSE(shifted.IsOval());
  EXPECT_TRUE(shifted.IsFinite());
  EXPECT_FALSE(shifted.GetBounds().IsEmpty());
  EXPECT_EQ(shifted.GetBounds(), Rect::MakeLTRB(15.0f, 16.0f, 45.0f, 46.0f));
  EXPECT_EQ(shifted.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(shifted.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(shifted.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(shifted.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(shifted, RoundSuperellipse::MakeRectRadii(
                         Rect::MakeXYWH(15.0f, 16.0f, 30.0f, 30.0f),
                         {
                             .top_left = Size(1.0f, 2.0f),
                             .top_right = Size(3.0f, 4.0f),
                             .bottom_left = Size(5.0f, 6.0f),
                             .bottom_right = Size(7.0f, 8.0f),
                         }));
}

TEST(RoundSuperellipseTest, ExpandScalar) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(5.0);

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(5.0f, 5.0f, 45.0f, 45.0f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(5.0f, 5.0f, 40.0f, 40.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));
}

TEST(RoundSuperellipseTest, ExpandTwoScalars) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(5.0, 6.0);

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(5.0f, 4.0f, 45.0f, 46.0f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(5.0f, 4.0f, 40.0f, 42.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));
}

TEST(RoundSuperellipseTest, ExpandFourScalars) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(5.0, 6.0, 7.0, 8.0);

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(5.0f, 4.0f, 47.0f, 48.0f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(5.0f, 4.0f, 42.0f, 44.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));
}

TEST(RoundSuperellipseTest, ContractScalar) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(-2.0);

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(12.0f, 12.0f, 38.0f, 38.0f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(12.0f, 12.0f, 26.0f, 26.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));
}

TEST(RoundSuperellipseTest, ContractTwoScalars) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(-1.0, -2.0);

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(11.0f, 12.0f, 39.0f, 38.0f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(11.0f, 12.0f, 28.0f, 26.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));
}

TEST(RoundSuperellipseTest, ContractFourScalars) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(-1.0, -1.5, -2.0, -2.5);

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(11.0f, 11.5f, 38.0f, 37.5f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(1.0f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(3.0f, 4.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(5.0f, 6.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(7.0f, 8.0f));

  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(11.0f, 11.5f, 27.0f, 26.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));
}

TEST(RoundSuperellipseTest, ContractAndRequireRadiiAdjustment) {
  RoundSuperellipse rse = RoundSuperellipse::MakeRectRadii(
      Rect::MakeXYWH(10.0f, 10.0f, 30.0f, 30.0f),
      {
          .top_left = Size(1.0f, 2.0f),
          .top_right = Size(3.0f, 4.0f),
          .bottom_left = Size(5.0f, 6.0f),
          .bottom_right = Size(7.0f, 8.0f),
      });
  RoundSuperellipse expanded = rse.Expand(-12.0);
  // Largest sum of paired radii sizes are the bottom and right edges
  // both of which sum to 12
  // Rect was 30x30 reduced by 12 on all sides leaving only 6x6, so all
  // radii are scaled by half to avoid overflowing the contracted rect

  EXPECT_FALSE(expanded.IsEmpty());
  EXPECT_FALSE(expanded.IsRect());
  EXPECT_FALSE(expanded.IsOval());
  EXPECT_TRUE(expanded.IsFinite());
  EXPECT_FALSE(expanded.GetBounds().IsEmpty());
  EXPECT_EQ(expanded.GetBounds(), Rect::MakeLTRB(22.0f, 22.0f, 28.0f, 28.0f));
  EXPECT_EQ(expanded.GetRadii().top_left, Size(0.5f, 1.0f));
  EXPECT_EQ(expanded.GetRadii().top_right, Size(1.5f, 2.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_left, Size(2.5f, 3.0f));
  EXPECT_EQ(expanded.GetRadii().bottom_right, Size(3.5f, 4.0f));

  // In this test, the MakeRectRadii constructor will make the same
  // adjustment to the radii that the Expand method applied.
  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(22.0f, 22.0f, 6.0f, 6.0f),
                          {
                              .top_left = Size(1.0f, 2.0f),
                              .top_right = Size(3.0f, 4.0f),
                              .bottom_left = Size(5.0f, 6.0f),
                              .bottom_right = Size(7.0f, 8.0f),
                          }));

  // In this test, the arguments to the constructor supply the correctly
  // adjusted radii (though there is no real way to tell other than
  // the result is the same).
  EXPECT_EQ(expanded, RoundSuperellipse::MakeRectRadii(
                          Rect::MakeXYWH(22.0f, 22.0f, 6.0f, 6.0f),
                          {
                              .top_left = Size(0.5f, 1.0f),
                              .top_right = Size(1.5f, 2.0f),
                              .bottom_left = Size(2.5f, 3.0f),
                              .bottom_right = Size(3.5f, 4.0f),
                          }));
}

TEST(RoundSuperellipseTest, NoCornerRoundSuperellipseContains) {
  Rect bounds = Rect::MakeLTRB(-50.0f, -50.0f, 50.0f, 50.0f);
  // Rounded superellipses of bounds with no corners contains corners just
  // barely.
  auto no_corners = RoundSuperellipse::MakeRectRadii(
      bounds, RoundingRadii::MakeRadii({0.0f, 0.0f}));

  EXPECT_TRUE(no_corners.Contains({-50, -50}));
  // Rectangles have half-in, half-out containment so we need
  // to be careful about testing containment of right/bottom corners.
  EXPECT_TRUE(no_corners.Contains({-50, 49.99}));
  EXPECT_TRUE(no_corners.Contains({49.99, -50}));
  EXPECT_TRUE(no_corners.Contains({49.99, 49.99}));
  EXPECT_FALSE(no_corners.Contains({-50.01, -50}));
  EXPECT_FALSE(no_corners.Contains({-50, -50.01}));
  EXPECT_FALSE(no_corners.Contains({-50.01, 50}));
  EXPECT_FALSE(no_corners.Contains({-50, 50.01}));
  EXPECT_FALSE(no_corners.Contains({50.01, -50}));
  EXPECT_FALSE(no_corners.Contains({50, -50.01}));
  EXPECT_FALSE(no_corners.Contains({50.01, 50}));
  EXPECT_FALSE(no_corners.Contains({50, 50.01}));
}

TEST(RoundSuperellipseTest, TinyCornerContains) {
  Rect bounds = Rect::MakeLTRB(-50.0f, -50.0f, 50.0f, 50.0f);
  // Rounded superellipses of bounds with even the tiniest corners does not
  // contain corners.
  auto tiny_corners = RoundSuperellipse::MakeRectRadii(
      bounds, RoundingRadii::MakeRadii({0.01f, 0.01f}));

  EXPECT_FALSE(tiny_corners.Contains({-50, -50}));
  EXPECT_FALSE(tiny_corners.Contains({-50, 50}));
  EXPECT_FALSE(tiny_corners.Contains({50, -50}));
  EXPECT_FALSE(tiny_corners.Contains({50, 50}));
}

TEST(RoundSuperellipseTest, UniformSquareContains) {
  Rect bounds = Rect::MakeLTRB(-50.0f, -50.0f, 50.0f, 50.0f);
  auto rr = RoundSuperellipse::MakeRectRadii(
      bounds, RoundingRadii::MakeRadii({5.0f, 5.0f}));

#define CHECK_POINT_AND_MIRRORS(p)                                     \
  CHECK_POINT_WITH_OFFSET(rr, (p), Point(0.02, 0.02));                 \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(1, -1), Point(0.02, -0.02)); \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(-1, 1), Point(-0.02, 0.02)); \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(-1, -1), Point(-0.02, -0.02));

  CHECK_POINT_AND_MIRRORS(Point(0, 49.995));      // Top
  CHECK_POINT_AND_MIRRORS(Point(44.245, 49.95));  // Top curve start
  CHECK_POINT_AND_MIRRORS(Point(45.72, 49.87));   // Top joint
  CHECK_POINT_AND_MIRRORS(Point(48.53, 48.53));   // Circular arc mid
  CHECK_POINT_AND_MIRRORS(Point(49.87, 45.72));   // Right joint
  CHECK_POINT_AND_MIRRORS(Point(49.95, 44.245));  // Right curve start
  CHECK_POINT_AND_MIRRORS(Point(49.995, 0));      // Right
#undef CHECK_POINT_AND_MIRRORS
}

TEST(RoundSuperellipseTest, UniformEllipticalContains) {
  Rect bounds = Rect::MakeLTRB(-50.0f, -50.0f, 50.0f, 50.0f);
  auto rr = RoundSuperellipse::MakeRectRadii(
      bounds, RoundingRadii::MakeRadii({5.0f, 10.0f}));

#define CHECK_POINT_AND_MIRRORS(p)                                     \
  CHECK_POINT_WITH_OFFSET(rr, (p), Point(0.02, 0.02));                 \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(1, -1), Point(0.02, -0.02)); \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(-1, 1), Point(-0.02, 0.02)); \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(-1, -1), Point(-0.02, -0.02));

  CHECK_POINT_AND_MIRRORS(Point(0, 49.995));       // Top
  CHECK_POINT_AND_MIRRORS(Point(44.245, 49.911));  // Top curve start
  CHECK_POINT_AND_MIRRORS(Point(45.72, 49.75));    // Top joint
  CHECK_POINT_AND_MIRRORS(Point(48.51, 47.07));    // Circular arc mid
  CHECK_POINT_AND_MIRRORS(Point(49.87, 41.44));    // Right joint
  CHECK_POINT_AND_MIRRORS(Point(49.95, 38.49));    // Right curve start
  CHECK_POINT_AND_MIRRORS(Point(49.995, 0));       // Right
#undef CHECK_POINT_AND_MIRRORS
}

TEST(RoundSuperellipseTest, UniformRectangularContains) {
  // The bounds is not centered at the origin and has unequal height and width.
  Rect bounds = Rect::MakeLTRB(0.0f, 0.0f, 50.0f, 100.0f);
  auto rr = RoundSuperellipse::MakeRectRadii(
      bounds, RoundingRadii::MakeRadii({23.0f, 30.0f}));

  Point center = bounds.GetCenter();
#define CHECK_POINT_AND_MIRRORS(p)                                   \
  CHECK_POINT_WITH_OFFSET(rr, (p - center) * Point(1, 1) + center,   \
                          Point(0.02, 0.02));                        \
  CHECK_POINT_WITH_OFFSET(rr, (p - center) * Point(1, -1) + center,  \
                          Point(0.02, -0.02));                       \
  CHECK_POINT_WITH_OFFSET(rr, (p - center) * Point(-1, 1) + center,  \
                          Point(-0.02, 0.02));                       \
  CHECK_POINT_WITH_OFFSET(rr, (p - center) * Point(-1, -1) + center, \
                          Point(-0.02, -0.02));

  CHECK_POINT_AND_MIRRORS(Point(24.99, 99.99));  // Bottom mid edge
  CHECK_POINT_AND_MIRRORS(Point(29.99, 99.64));
  CHECK_POINT_AND_MIRRORS(Point(34.99, 98.06));
  CHECK_POINT_AND_MIRRORS(Point(39.99, 94.73));
  CHECK_POINT_AND_MIRRORS(Point(44.13, 89.99));
  CHECK_POINT_AND_MIRRORS(Point(48.46, 79.99));
  CHECK_POINT_AND_MIRRORS(Point(49.70, 69.99));
  CHECK_POINT_AND_MIRRORS(Point(49.97, 59.99));
  CHECK_POINT_AND_MIRRORS(Point(49.99, 49.99));  // Right mid edge

#undef CHECK_POINT_AND_MIRRORS
}

TEST(RoundSuperellipseTest, SlimDiagonalContains) {
  // This shape has large radii on one diagonal and tiny radii on the other,
  // resulting in a almond-like shape placed diagonally (NW to SE).
  Rect bounds = Rect::MakeLTRB(-50.0f, -50.0f, 50.0f, 50.0f);
  auto rr = RoundSuperellipse::MakeRectRadii(
      bounds, {
                  .top_left = Size(1.0, 1.0),
                  .top_right = Size(99.0, 99.0),
                  .bottom_left = Size(99.0, 99.0),
                  .bottom_right = Size(1.0, 1.0),
              });

  EXPECT_TRUE(rr.Contains(Point{0, 0}));
  EXPECT_FALSE(rr.Contains(Point{-49.999, -49.999}));
  EXPECT_FALSE(rr.Contains(Point{-49.999, 49.999}));
  EXPECT_FALSE(rr.Contains(Point{49.999, 49.999}));
  EXPECT_FALSE(rr.Contains(Point{49.999, -49.999}));

  // The pointy ends at the NE and SW corners
  CHECK_POINT_WITH_OFFSET(rr, Point(-49.70, -49.70), Point(-0.02, -0.02));
  CHECK_POINT_WITH_OFFSET(rr, Point(49.70, 49.70), Point(0.02, 0.02));

// Checks two points symmetrical to the origin.
#define CHECK_DIAGONAL_POINTS(p)                        \
  CHECK_POINT_WITH_OFFSET(rr, (p), Point(0.02, -0.02)); \
  CHECK_POINT_WITH_OFFSET(rr, (p) * Point(-1, -1), Point(-0.02, 0.02));

  // A few other points along the edge
  CHECK_DIAGONAL_POINTS(Point(-40.0, -49.59));
  CHECK_DIAGONAL_POINTS(Point(-20.0, -45.64));
  CHECK_DIAGONAL_POINTS(Point(0.0, -37.01));
  CHECK_DIAGONAL_POINTS(Point(20.0, -21.96));
  CHECK_DIAGONAL_POINTS(Point(21.05, -20.92));
  CHECK_DIAGONAL_POINTS(Point(40.0, 5.68));
#undef CHECK_POINT_AND_MIRRORS
}

TEST(RoundSuperellipseTest, PointsOutsideOfSharpCorner) {
  Rect bounds = Rect::MakeLTRB(196.0f, 0.0f, 294.0f, 28.0f);
  // Regression test for a case where RoundSuperellipseParam::Contains
  // previously failed. Although the bounding rect filter of
  // `RoundSuperellipse::Contains` would reject this point, this test ensures
  // the internal logic of RoundSuperellipseParam::Contains is now correct.
  auto rr = RoundSuperellipseParam::MakeBoundsRadii(
      bounds, {
                  .top_left = Size(0.0, 0.0),
                  .top_right = Size(3.0, 3.0),
                  .bottom_left = Size(0.0, 0.0),
                  .bottom_right = Size(3.0, 3.0),
              });

  EXPECT_FALSE(rr.Contains(Point{147.0, 14.0}));
}

TEST(RoundSuperellipseTest,
     PathForRectangularRseWithShapeCornersShouldBeWithinBounds) {
  Rect bounds = Rect::MakeLTRB(34.0f, 242.0f, 766.0f, 358.0f);
  // Regression test for https://github.com/flutter/flutter/issues/170593.
  // The issue was caused by incorrect calculation when building paths for
  // rounded superellipses with sharp corners and unequal width and height.
  // Since the most obvious symptom of the issue is some points being
  // incorrectly placed out of bounds, this test case simply verifies that all
  // points are within the bounds.

  auto rr = RoundSuperellipseParam::MakeBoundsRadii(
      bounds, {
                  .top_left = Size(14.0, 14.0),
                  .top_right = Size(14.0, 14.0),
                  .bottom_left = Size(0.0, 0.0),
                  .bottom_right = Size(0.0, 0.0),
              });
  SpyPathReceiver receiver;
  receiver.SpyLineTo(
      [&](const Point& p2) { EXPECT_TRUE(bounds.ContainsInclusive(p2)); });
  receiver.SpyCubicTo([&](const Point& cp1, const Point& cp2, const Point& p2) {
    EXPECT_TRUE(bounds.ContainsInclusive(p2));
  });

  rr.Dispatch(receiver);
}

}  // namespace testing
}  // namespace impeller
