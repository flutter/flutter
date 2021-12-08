// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

class PathBuilder {
 public:
  PathBuilder();

  ~PathBuilder();

  Path CreatePath() const;

  const Path& GetCurrentPath() const;

  PathBuilder& MoveTo(Point point, bool relative = false);

  PathBuilder& Close();

  PathBuilder& LineTo(Point point, bool relative = false);

  PathBuilder& HorizontalLineTo(Scalar x, bool relative = false);

  PathBuilder& VerticalLineTo(Scalar y, bool relative = false);

  PathBuilder& QuadraticCurveTo(Point point,
                                Point controlPoint,
                                bool relative = false);

  PathBuilder& SmoothQuadraticCurveTo(Point point, bool relative = false);

  PathBuilder& CubicCurveTo(Point point,
                            Point controlPoint1,
                            Point controlPoint2,
                            bool relative = false);

  PathBuilder& SmoothCubicCurveTo(Point point,
                                  Point controlPoint2,
                                  bool relative = false);

  PathBuilder& AddRect(Rect rect);

  PathBuilder& AddCircle(const Point& center, Scalar radius);

  PathBuilder& AddOval(const Rect& rect);

  PathBuilder& AddLine(const Point& p1, const Point& p2);

  struct RoundingRadii {
    Point top_left;
    Point bottom_left;
    Point top_right;
    Point bottom_right;

    RoundingRadii() = default;

    RoundingRadii(Scalar p_top_left,
                  Scalar p_bottom_left,
                  Scalar p_top_right,
                  Scalar p_bottom_right)
        : top_left(p_top_left, p_top_left),
          bottom_left(p_bottom_left, p_bottom_left),
          top_right(p_top_right, p_top_right),
          bottom_right(p_bottom_right, p_bottom_right) {}

    bool AreAllZero() const {
      return top_left.IsZero() &&     //
             bottom_left.IsZero() &&  //
             top_right.IsZero() &&    //
             bottom_right.IsZero();
    }
  };

  PathBuilder& AddRoundedRect(Rect rect, RoundingRadii radii);

  PathBuilder& AddRoundedRect(Rect rect, Scalar radius);

 private:
  Point subpath_start_;
  Point current_;
  Path prototype_;

  Point ReflectedQuadraticControlPoint1() const;

  Point ReflectedCubicControlPoint1() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PathBuilder);
};

}  // namespace impeller
