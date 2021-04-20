/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include "Path.h"
#include "Rect.h"
#include "flutter/fml/macros.h"

namespace rl {
namespace geom {

class PathBuilder {
 public:
  PathBuilder();

  ~PathBuilder();

  Path path() const;

  PathBuilder& moveTo(Point point, bool relative = false);

  PathBuilder& close();

  PathBuilder& lineTo(Point point, bool relative = false);

  PathBuilder& horizontalLineTo(double x, bool relative = false);

  PathBuilder& verticalLineTo(double y, bool relative = false);

  PathBuilder& quadraticCurveTo(Point point,
                                Point controlPoint,
                                bool relative = false);

  PathBuilder& smoothQuadraticCurveTo(Point point, bool relative = false);

  PathBuilder& cubicCurveTo(Point point,
                            Point controlPoint1,
                            Point controlPoint2,
                            bool relative = false);

  PathBuilder& smoothCubicCurveTo(Point point,
                                  Point controlPoint2,
                                  bool relative = false);

  PathBuilder& addRect(Rect rect);

  PathBuilder& addRoundedRect(Rect rect, double radius);

  PathBuilder& addCircle(const Point& center, double radius);

  PathBuilder& addEllipse(const Point& center, const Size& size);

  struct RoundingRadii {
    double topLeft;
    double bottomLeft;
    double topRight;
    double bottomRight;

    RoundingRadii()
        : topLeft(0.0), bottomLeft(0.0), topRight(0.0), bottomRight(0.0) {}

    RoundingRadii(double pTopLeft,
                  double pBottomLeft,
                  double pTopRight,
                  double pBottomRight)
        : topLeft(pTopLeft),
          bottomLeft(pBottomLeft),
          topRight(pTopRight),
          bottomRight(pBottomRight) {}
  };

  PathBuilder& addRoundedRect(Rect rect, RoundingRadii radii);

 private:
  Point _subpathStart;
  Point _current;
  Path _prototype;

  Point reflectedQuadraticControlPoint1() const;

  Point reflectedCubicControlPoint1() const;

  FML_DISALLOW_COPY_AND_ASSIGN(PathBuilder);
};

}  // namespace geom
}  // namespace rl
