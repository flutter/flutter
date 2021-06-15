// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_builder.h"

namespace impeller {

static const Scalar kArcApproximationMagic = 0.551915024494;

PathBuilder::PathBuilder() = default;

PathBuilder::~PathBuilder() = default;

Path PathBuilder::CreatePath() const {
  return prototype_;
}

PathBuilder& PathBuilder::MoveTo(Point point, bool relative) {
  current_ = relative ? current_ + point : point;
  subpath_start_ = current_;
  return *this;
}

PathBuilder& PathBuilder::Close() {
  LineTo(subpath_start_);
  return *this;
}

PathBuilder& PathBuilder::LineTo(Point point, bool relative) {
  point = relative ? current_ + point : point;
  prototype_.AddLinearComponent(current_, point);
  current_ = point;
  return *this;
}

PathBuilder& PathBuilder::HorizontalLineTo(Scalar x, bool relative) {
  Point endpoint =
      relative ? Point{current_.x + x, current_.y} : Point{x, current_.y};
  prototype_.AddLinearComponent(current_, endpoint);
  current_ = endpoint;
  return *this;
}

PathBuilder& PathBuilder::VerticalLineTo(Scalar y, bool relative) {
  Point endpoint =
      relative ? Point{current_.x, current_.y + y} : Point{current_.x, y};
  prototype_.AddLinearComponent(current_, endpoint);
  current_ = endpoint;
  return *this;
}

PathBuilder& PathBuilder::QuadraticCurveTo(Point point,
                                           Point controlPoint,
                                           bool relative) {
  point = relative ? current_ + point : point;
  controlPoint = relative ? current_ + controlPoint : controlPoint;
  prototype_.AddQuadraticComponent(current_, controlPoint, point);
  current_ = point;
  return *this;
}

Point PathBuilder::ReflectedQuadraticControlPoint1() const {
  /*
   *  If there is no previous command or if the previous command was not a
   *  quadratic, assume the control point is coincident with the current point.
   */
  if (prototype_.GetComponentCount() == 0) {
    return current_;
  }

  QuadraticPathComponent quad;
  if (!prototype_.GetQuadraticComponentAtIndex(
          prototype_.GetComponentCount() - 1, quad)) {
    return current_;
  }

  /*
   *  The control point is assumed to be the reflection of the control point on
   *  the previous command relative to the current point.
   */
  return (current_ * 2.0) - quad.cp;
}

PathBuilder& PathBuilder::SmoothQuadraticCurveTo(Point point, bool relative) {
  point = relative ? current_ + point : point;
  /*
   *  The reflected control point is absolute and we made the endpoint absolute
   *  too. So there the last argument is always false (i.e, not relative).
   */
  QuadraticCurveTo(point, ReflectedQuadraticControlPoint1(), false);
  return *this;
}

PathBuilder& PathBuilder::CubicCurveTo(Point point,
                                       Point controlPoint1,
                                       Point controlPoint2,
                                       bool relative) {
  controlPoint1 = relative ? current_ + controlPoint1 : controlPoint1;
  controlPoint2 = relative ? current_ + controlPoint2 : controlPoint2;
  point = relative ? current_ + point : point;
  prototype_.AddCubicComponent(current_, controlPoint1, controlPoint2, point);
  current_ = point;
  return *this;
}

Point PathBuilder::ReflectedCubicControlPoint1() const {
  /*
   *  If there is no previous command or if the previous command was not a
   *  cubic, assume the first control point is coincident with the current
   *  point.
   */
  if (prototype_.GetComponentCount() == 0) {
    return current_;
  }

  CubicPathComponent cubic;
  if (!prototype_.GetCubicComponentAtIndex(prototype_.GetComponentCount() - 1,
                                           cubic)) {
    return current_;
  }

  /*
   *  The first control point is assumed to be the reflection of the second
   *  control point on the previous command relative to the current point.
   */
  return (current_ * 2.0) - cubic.cp2;
}

PathBuilder& PathBuilder::SmoothCubicCurveTo(Point point,
                                             Point controlPoint2,
                                             bool relative) {
  auto controlPoint1 = ReflectedCubicControlPoint1();
  controlPoint2 = relative ? current_ + controlPoint2 : controlPoint2;
  auto endpoint = relative ? current_ + point : point;

  CubicCurveTo(endpoint,       // endpoint
               controlPoint1,  // control point 1
               controlPoint2,  // control point 2
               false           // relative since all points are already absolute
  );
  return *this;
}

PathBuilder& PathBuilder::AddRect(Rect rect) {
  current_ = rect.origin;

  auto topLeft = rect.origin;
  auto bottomLeft = rect.origin + Point{0.0, rect.size.height};
  auto bottomRight = rect.origin + Point{rect.size.width, rect.size.height};
  auto topRight = rect.origin + Point{rect.size.width, 0.0};

  prototype_.AddLinearComponent(topLeft, bottomLeft)
      .AddLinearComponent(bottomLeft, bottomRight)
      .AddLinearComponent(bottomRight, topRight)
      .AddLinearComponent(topRight, topLeft);

  return *this;
}

PathBuilder& PathBuilder::AddCircle(const Point& center, Scalar radius) {
  current_ = center + Point{0.0, radius};

  const Scalar diameter = radius * 2.0;
  const Scalar magic = kArcApproximationMagic * radius;

  prototype_.AddCubicComponent(
      {center.x + radius, center.y},                     //
      {center.x + radius + magic, center.y},             //
      {center.x + diameter, center.y + radius - magic},  //
      {center.x + diameter, center.y + radius}           //
  );

  prototype_.AddCubicComponent(
      {center.x + diameter, center.y + radius},          //
      {center.x + diameter, center.y + radius + magic},  //
      {center.x + radius + magic, center.y + diameter},  //
      {center.x + radius, center.y + diameter}           //
  );

  prototype_.AddCubicComponent(
      {center.x + radius, center.y + diameter},          //
      {center.x + radius - magic, center.y + diameter},  //
      {center.x, center.y + radius + magic},             //
      {center.x, center.y + radius}                      //
  );

  prototype_.AddCubicComponent({center.x, center.y + radius},          //
                               {center.x, center.y + radius - magic},  //
                               {center.x + radius - magic, center.y},  //
                               {center.x + radius, center.y}           //
  );

  return *this;
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, Scalar radius) {
  return radius == 0.0 ? AddRect(rect)
                       : AddRoundedRect(rect, {radius, radius, radius, radius});
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, RoundingRadii radii) {
  current_ = rect.origin + Point{radii.topLeft, 0.0};

  const Scalar magicTopRight = kArcApproximationMagic * radii.topRight;
  const Scalar magicBottomRight = kArcApproximationMagic * radii.bottomRight;
  const Scalar magicBottomLeft = kArcApproximationMagic * radii.bottomLeft;
  const Scalar magicTopLeft = kArcApproximationMagic * radii.topLeft;

  /*
   *  Top line.
   */
  prototype_.AddLinearComponent(
      {rect.origin.x + radii.topLeft, rect.origin.y},
      {rect.origin.x + rect.size.width - radii.topRight, rect.origin.y});

  /*
   *  Top right arc.
   */
  prototype_.AddCubicComponent(
      {rect.origin.x + rect.size.width - radii.topRight, rect.origin.y},
      {rect.origin.x + rect.size.width - radii.topRight + magicTopRight,
       rect.origin.y},
      {rect.origin.x + rect.size.width,
       rect.origin.y + radii.topRight - magicTopRight},
      {rect.origin.x + rect.size.width, rect.origin.y + radii.topRight});

  /*
   *  Right line.
   */
  prototype_.AddLinearComponent(
      {rect.origin.x + rect.size.width, rect.origin.y + radii.topRight},
      {rect.origin.x + rect.size.width,
       rect.origin.y + rect.size.height - radii.bottomRight});

  /*
   *  Bottom right arc.
   */
  prototype_.AddCubicComponent(
      {rect.origin.x + rect.size.width,
       rect.origin.y + rect.size.height - radii.bottomRight},
      {rect.origin.x + rect.size.width,
       rect.origin.y + rect.size.height - radii.bottomRight + magicBottomRight},
      {rect.origin.x + rect.size.width - radii.bottomRight + magicBottomRight,
       rect.origin.y + rect.size.height},
      {rect.origin.x + rect.size.width - radii.bottomRight,
       rect.origin.y + rect.size.height});

  /*
   *  Bottom line.
   */
  prototype_.AddLinearComponent(
      {rect.origin.x + rect.size.width - radii.bottomRight,
       rect.origin.y + rect.size.height},
      {rect.origin.x + radii.bottomLeft, rect.origin.y + rect.size.height});

  /*
   *  Bottom left arc.
   */
  prototype_.AddCubicComponent(
      {rect.origin.x + radii.bottomLeft, rect.origin.y + rect.size.height},
      {rect.origin.x + radii.bottomLeft - magicBottomLeft,
       rect.origin.y + rect.size.height},
      {rect.origin.x,
       rect.origin.y + rect.size.height - radii.bottomLeft + magicBottomLeft},
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottomLeft});

  /*
   *  Left line.
   */
  prototype_.AddLinearComponent(
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottomLeft},
      {rect.origin.x, rect.origin.y + radii.topLeft});

  /*
   *  Top left arc.
   */
  prototype_.AddCubicComponent(
      {rect.origin.x, rect.origin.y + radii.topLeft},
      {rect.origin.x, rect.origin.y + radii.topLeft - magicTopLeft},
      {rect.origin.x + radii.topLeft - magicTopLeft, rect.origin.y},
      {rect.origin.x + radii.topLeft, rect.origin.y});

  return *this;
}

PathBuilder& PathBuilder::AddEllipse(const Point& center, const Size& radius) {
  current_ = center + Point{0.0, radius.height};

  const Size diameter = {radius.width * 2.0f, radius.height * 2.0f};
  const Size magic = {kArcApproximationMagic * radius.width,
                      kArcApproximationMagic * radius.height};

  prototype_.AddCubicComponent(
      {center.x + radius.width, center.y},                                   //
      {center.x + radius.width + magic.width, center.y},                     //
      {center.x + diameter.width, center.y + radius.height - magic.height},  //
      {center.x + diameter.width, center.y + radius.height}                  //
  );

  prototype_.AddCubicComponent(
      {center.x + diameter.width, center.y + radius.height},                 //
      {center.x + diameter.width, center.y + radius.height + magic.height},  //
      {center.x + radius.width + magic.width, center.y + diameter.height},   //
      {center.x + radius.width, center.y + diameter.height}                  //
  );

  prototype_.AddCubicComponent(
      {center.x + radius.width, center.y + diameter.height},                //
      {center.x + radius.width - magic.width, center.y + diameter.height},  //
      {center.x, center.y + radius.height + magic.height},                  //
      {center.x, center.y + radius.height}                                  //
  );

  prototype_.AddCubicComponent(
      {center.x, center.y + radius.height},                 //
      {center.x, center.y + radius.height - magic.height},  //
      {center.x + radius.width - magic.width, center.y},    //
      {center.x + radius.width, center.y}                   //
  );

  return *this;
}

}  // namespace impeller
