// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_builder.h"

#include <cmath>

namespace impeller {

PathBuilder::PathBuilder() = default;

PathBuilder::~PathBuilder() = default;

Path PathBuilder::CopyPath(FillType fill) const {
  auto path = prototype_;
  path.SetFillType(fill);
  return path;
}

Path PathBuilder::TakePath(FillType fill) {
  auto path = prototype_;
  path.SetFillType(fill);
  path.SetConvexity(convexity_);
  return path;
}

PathBuilder& PathBuilder::MoveTo(Point point, bool relative) {
  current_ = relative ? current_ + point : point;
  subpath_start_ = current_;
  prototype_.AddContourComponent(current_);
  return *this;
}

PathBuilder& PathBuilder::Close() {
  LineTo(subpath_start_);
  prototype_.SetContourClosed(true);
  prototype_.AddContourComponent(current_);
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

PathBuilder& PathBuilder::QuadraticCurveTo(Point controlPoint,
                                           Point point,
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

PathBuilder& PathBuilder::SetConvexity(Convexity value) {
  convexity_ = value;
  return *this;
}

PathBuilder& PathBuilder::CubicCurveTo(Point controlPoint1,
                                       Point controlPoint2,
                                       Point point,
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

PathBuilder& PathBuilder::SmoothCubicCurveTo(Point controlPoint2,
                                             Point point,
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

PathBuilder& PathBuilder::AddQuadraticCurve(Point p1, Point cp, Point p2) {
  MoveTo(p1);
  prototype_.AddQuadraticComponent(p1, cp, p2);
  return *this;
}

PathBuilder& PathBuilder::AddCubicCurve(Point p1,
                                        Point cp1,
                                        Point cp2,
                                        Point p2) {
  MoveTo(p1);
  prototype_.AddCubicComponent(p1, cp1, cp2, p2);
  return *this;
}

PathBuilder& PathBuilder::AddRect(Rect rect) {
  current_ = rect.origin;

  auto tl = rect.origin;
  auto bl = rect.origin + Point{0.0, rect.size.height};
  auto br = rect.origin + Point{rect.size.width, rect.size.height};
  auto tr = rect.origin + Point{rect.size.width, 0.0};

  MoveTo(tl);
  prototype_.AddLinearComponent(tl, tr)
      .AddLinearComponent(tr, br)
      .AddLinearComponent(br, bl);
  Close();

  return *this;
}

PathBuilder& PathBuilder::AddCircle(const Point& c, Scalar r) {
  return AddOval(Rect{c.x - r, c.y - r, 2.0f * r, 2.0f * r});
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, Scalar radius) {
  return radius <= 0.0 ? AddRect(rect)
                       : AddRoundedRect(rect, {radius, radius, radius, radius});
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, RoundingRadii radii) {
  if (radii.AreAllZero()) {
    return AddRect(rect);
  }

  current_ = rect.origin + Point{radii.top_left.x, 0.0};

  MoveTo({rect.origin.x + radii.top_left.x, rect.origin.y});

  //----------------------------------------------------------------------------
  // Top line.
  //
  prototype_.AddLinearComponent(
      {rect.origin.x + radii.top_left.x, rect.origin.y},
      {rect.origin.x + rect.size.width - radii.top_right.x, rect.origin.y});

  //----------------------------------------------------------------------------
  // Top right arc.
  //
  AddRoundedRectTopRight(rect, radii);

  //----------------------------------------------------------------------------
  // Right line.
  //
  prototype_.AddLinearComponent(
      {rect.origin.x + rect.size.width, rect.origin.y + radii.top_right.y},
      {rect.origin.x + rect.size.width,
       rect.origin.y + rect.size.height - radii.bottom_right.y});

  //----------------------------------------------------------------------------
  // Bottom right arc.
  //
  AddRoundedRectBottomRight(rect, radii);

  //----------------------------------------------------------------------------
  // Bottom line.
  //
  prototype_.AddLinearComponent(
      {rect.origin.x + rect.size.width - radii.bottom_right.x,
       rect.origin.y + rect.size.height},
      {rect.origin.x + radii.bottom_left.x, rect.origin.y + rect.size.height});

  //----------------------------------------------------------------------------
  // Bottom left arc.
  //
  AddRoundedRectBottomLeft(rect, radii);

  //----------------------------------------------------------------------------
  // Left line.
  //
  prototype_.AddLinearComponent(
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottom_left.y},
      {rect.origin.x, rect.origin.y + radii.top_left.y});

  //----------------------------------------------------------------------------
  // Top left arc.
  //
  AddRoundedRectTopLeft(rect, radii);

  Close();

  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectTopLeft(Rect rect,
                                                RoundingRadii radii) {
  const auto magic_top_left = radii.top_left * kArcApproximationMagic;
  prototype_.AddCubicComponent(
      {rect.origin.x, rect.origin.y + radii.top_left.y},
      {rect.origin.x, rect.origin.y + radii.top_left.y - magic_top_left.y},
      {rect.origin.x + radii.top_left.x - magic_top_left.x, rect.origin.y},
      {rect.origin.x + radii.top_left.x, rect.origin.y});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectTopRight(Rect rect,
                                                 RoundingRadii radii) {
  const auto magic_top_right = radii.top_right * kArcApproximationMagic;
  prototype_.AddCubicComponent(
      {rect.origin.x + rect.size.width - radii.top_right.x, rect.origin.y},
      {rect.origin.x + rect.size.width - radii.top_right.x + magic_top_right.x,
       rect.origin.y},
      {rect.origin.x + rect.size.width,
       rect.origin.y + radii.top_right.y - magic_top_right.y},
      {rect.origin.x + rect.size.width, rect.origin.y + radii.top_right.y});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectBottomRight(Rect rect,
                                                    RoundingRadii radii) {
  const auto magic_bottom_right = radii.bottom_right * kArcApproximationMagic;
  prototype_.AddCubicComponent(
      {rect.origin.x + rect.size.width,
       rect.origin.y + rect.size.height - radii.bottom_right.y},
      {rect.origin.x + rect.size.width, rect.origin.y + rect.size.height -
                                            radii.bottom_right.y +
                                            magic_bottom_right.y},
      {rect.origin.x + rect.size.width - radii.bottom_right.x +
           magic_bottom_right.x,
       rect.origin.y + rect.size.height},
      {rect.origin.x + rect.size.width - radii.bottom_right.x,
       rect.origin.y + rect.size.height});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectBottomLeft(Rect rect,
                                                   RoundingRadii radii) {
  const auto magic_bottom_left = radii.bottom_left * kArcApproximationMagic;
  prototype_.AddCubicComponent(
      {rect.origin.x + radii.bottom_left.x, rect.origin.y + rect.size.height},
      {rect.origin.x + radii.bottom_left.x - magic_bottom_left.x,
       rect.origin.y + rect.size.height},
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottom_left.y +
                          magic_bottom_left.y},
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottom_left.y});
  return *this;
}

PathBuilder& PathBuilder::AddArc(const Rect& oval_bounds,
                                 Radians start,
                                 Radians sweep,
                                 bool use_center) {
  if (sweep.radians < 0) {
    start.radians += sweep.radians;
    sweep.radians *= -1;
  }
  sweep.radians = std::min(k2Pi, sweep.radians);
  start.radians = std::fmod(start.radians, k2Pi);

  const Point radius = {oval_bounds.size.width * 0.5f,
                        oval_bounds.size.height * 0.5f};
  const Point center = {oval_bounds.origin.x + radius.x,
                        oval_bounds.origin.y + radius.y};

  Vector2 p1_unit(std::cos(start.radians), std::sin(start.radians));

  if (use_center) {
    MoveTo(center);
    LineTo(center + p1_unit * radius);
  } else {
    MoveTo(center + p1_unit * radius);
  }

  while (sweep.radians > 0) {
    Vector2 p2_unit;
    Scalar quadrant_angle;
    if (sweep.radians < kPiOver2) {
      quadrant_angle = sweep.radians;
      p2_unit = Vector2(std::cos(start.radians + quadrant_angle),
                        std::sin(start.radians + quadrant_angle));
    } else {
      quadrant_angle = kPiOver2;
      p2_unit = Vector2(-p1_unit.y, p1_unit.x);
    }

    Vector2 arc_cp_lengths =
        (quadrant_angle / kPiOver2) * kArcApproximationMagic * radius;

    Point p1 = center + p1_unit * radius;
    Point p2 = center + p2_unit * radius;
    Point cp1 = p1 + Vector2(-p1_unit.y, p1_unit.x) * arc_cp_lengths;
    Point cp2 = p2 + Vector2(p2_unit.y, -p2_unit.x) * arc_cp_lengths;

    prototype_.AddCubicComponent(p1, cp1, cp2, p2);
    current_ = p2;

    start.radians += quadrant_angle;
    sweep.radians -= quadrant_angle;
    p1_unit = p2_unit;
  }

  if (use_center) {
    Close();
  }

  return *this;
}

PathBuilder& PathBuilder::AddOval(const Rect& container) {
  const Point r = {container.size.width * 0.5f, container.size.height * 0.5f};
  const Point c = {container.origin.x + r.x, container.origin.y + r.y};
  const Point m = {kArcApproximationMagic * r.x, kArcApproximationMagic * r.y};

  MoveTo({c.x, c.y - r.y});

  //----------------------------------------------------------------------------
  // Top right arc.
  //
  prototype_.AddCubicComponent({c.x, c.y - r.y},        // p1
                               {c.x + m.x, c.y - r.y},  // cp1
                               {c.x + r.x, c.y - m.y},  // cp2
                               {c.x + r.x, c.y}         // p2
  );

  //----------------------------------------------------------------------------
  // Bottom right arc.
  //
  prototype_.AddCubicComponent({c.x + r.x, c.y},        // p1
                               {c.x + r.x, c.y + m.y},  // cp1
                               {c.x + m.x, c.y + r.y},  // cp2
                               {c.x, c.y + r.y}         // p2
  );

  //----------------------------------------------------------------------------
  // Bottom left arc.
  //
  prototype_.AddCubicComponent({c.x, c.y + r.y},        // p1
                               {c.x - m.x, c.y + r.y},  // cp1
                               {c.x - r.x, c.y + m.y},  // cp2
                               {c.x - r.x, c.y}         // p2
  );

  //----------------------------------------------------------------------------
  // Top left arc.
  //
  prototype_.AddCubicComponent({c.x - r.x, c.y},        // p1
                               {c.x - r.x, c.y - m.y},  // cp1
                               {c.x - m.x, c.y - r.y},  // cp2
                               {c.x, c.y - r.y}         // p2
  );

  Close();

  return *this;
}

PathBuilder& PathBuilder::AddLine(const Point& p1, const Point& p2) {
  MoveTo(p1);
  prototype_.AddLinearComponent(p1, p2);
  return *this;
}

const Path& PathBuilder::GetCurrentPath() const {
  return prototype_;
}

PathBuilder& PathBuilder::AddPath(const Path& path) {
  auto linear = [&](size_t index, const LinearPathComponent& l) {
    prototype_.AddLinearComponent(l.p1, l.p2);
  };
  auto quadratic = [&](size_t index, const QuadraticPathComponent& q) {
    prototype_.AddQuadraticComponent(q.p1, q.cp, q.p2);
  };
  auto cubic = [&](size_t index, const CubicPathComponent& c) {
    prototype_.AddCubicComponent(c.p1, c.cp1, c.cp2, c.p2);
  };
  auto move = [&](size_t index, const ContourComponent& m) {
    prototype_.AddContourComponent(m.destination);
  };
  path.EnumerateComponents(linear, quadratic, cubic, move);
  return *this;
}

}  // namespace impeller
