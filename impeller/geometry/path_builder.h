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

  PathBuilder& AddRoundedRect(Rect rect, Scalar radius);

  PathBuilder& AddCircle(const Point& center, Scalar radius);

  PathBuilder& AddOval(const Rect& rect);

  PathBuilder& AddLine(const Point& p1, const Point& p2);

  struct RoundingRadii {
    Scalar topLeft = 0.0;
    Scalar bottomLeft = 0.0;
    Scalar topRight = 0.0;
    Scalar bottomRight = 0.0;

    RoundingRadii() {}

    RoundingRadii(Scalar pTopLeft,
                  Scalar pBottomLeft,
                  Scalar pTopRight,
                  Scalar pBottomRight)
        : topLeft(pTopLeft),
          bottomLeft(pBottomLeft),
          topRight(pTopRight),
          bottomRight(pBottomRight) {}
  };

  PathBuilder& AddRoundedRect(Rect rect, RoundingRadii radii);

 private:
  Point subpath_start_;
  Point current_;
  Path prototype_;

  Point ReflectedQuadraticControlPoint1() const;

  Point ReflectedCubicControlPoint1() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PathBuilder);
};

}  // namespace impeller
