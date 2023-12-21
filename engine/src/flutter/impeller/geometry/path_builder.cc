// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_builder.h"

#include <cmath>

namespace impeller {

PathBuilder::PathBuilder() = default;

PathBuilder::~PathBuilder() = default;

Path PathBuilder::CopyPath(FillType fill) const {
  auto path = prototype_.Clone();
  path.SetFillType(fill);
  return path;
}

Path PathBuilder::TakePath(FillType fill) {
  auto path = std::move(prototype_);
  path.SetFillType(fill);
  path.SetConvexity(convexity_);
  if (!did_compute_bounds_) {
    path.ComputeBounds();
  }
  did_compute_bounds_ = false;
  return path;
}

void PathBuilder::Reserve(size_t point_size, size_t verb_size) {
  prototype_.points_.reserve(point_size);
  prototype_.points_.reserve(verb_size);
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
  auto origin = rect.GetOrigin();
  auto size = rect.GetSize();

  auto tl = origin;
  auto bl = origin + Point{0.0, size.height};
  auto br = origin + size;
  auto tr = origin + Point{size.width, 0.0};

  MoveTo(tl);
  LineTo(tr);
  LineTo(br);
  LineTo(bl);
  Close();

  return *this;
}

PathBuilder& PathBuilder::AddCircle(const Point& c, Scalar r) {
  return AddOval(Rect::MakeXYWH(c.x - r, c.y - r, 2.0f * r, 2.0f * r));
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, Scalar radius) {
  return radius <= 0.0 ? AddRect(rect)
                       : AddRoundedRect(rect, RoundingRadii(radius));
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, Size radii) {
  return radii.width <= 0 || radii.height <= 0
             ? AddRect(rect)
             : AddRoundedRect(rect, RoundingRadii(radii));
}

PathBuilder& PathBuilder::AddRoundedRect(Rect rect, RoundingRadii radii) {
  if (radii.AreAllZero()) {
    return AddRect(rect);
  }

  auto rect_origin = rect.GetOrigin();
  auto rect_size = rect.GetSize();

  current_ = rect_origin + Point{radii.top_left.x, 0.0};

  MoveTo({rect_origin.x + radii.top_left.x, rect_origin.y});

  //----------------------------------------------------------------------------
  // Top line.
  //
  prototype_.AddLinearComponent(
      {rect_origin.x + radii.top_left.x, rect_origin.y},
      {rect_origin.x + rect_size.width - radii.top_right.x, rect_origin.y});

  //----------------------------------------------------------------------------
  // Top right arc.
  //
  AddRoundedRectTopRight(rect, radii);

  //----------------------------------------------------------------------------
  // Right line.
  //
  prototype_.AddLinearComponent(
      {rect_origin.x + rect_size.width, rect_origin.y + radii.top_right.y},
      {rect_origin.x + rect_size.width,
       rect_origin.y + rect_size.height - radii.bottom_right.y});

  //----------------------------------------------------------------------------
  // Bottom right arc.
  //
  AddRoundedRectBottomRight(rect, radii);

  //----------------------------------------------------------------------------
  // Bottom line.
  //
  prototype_.AddLinearComponent(
      {rect_origin.x + rect_size.width - radii.bottom_right.x,
       rect_origin.y + rect_size.height},
      {rect_origin.x + radii.bottom_left.x, rect_origin.y + rect_size.height});

  //----------------------------------------------------------------------------
  // Bottom left arc.
  //
  AddRoundedRectBottomLeft(rect, radii);

  //----------------------------------------------------------------------------
  // Left line.
  //
  prototype_.AddLinearComponent(
      {rect_origin.x, rect_origin.y + rect_size.height - radii.bottom_left.y},
      {rect_origin.x, rect_origin.y + radii.top_left.y});

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
  const auto corner = rect.GetOrigin();
  prototype_.AddCubicComponent(
      {corner.x, corner.y + radii.top_left.y},
      {corner.x, corner.y + radii.top_left.y - magic_top_left.y},
      {corner.x + radii.top_left.x - magic_top_left.x, corner.y},
      {corner.x + radii.top_left.x, corner.y});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectTopRight(Rect rect,
                                                 RoundingRadii radii) {
  const auto magic_top_right = radii.top_right * kArcApproximationMagic;
  const auto corner = rect.GetOrigin() + Point{rect.GetWidth(), 0};
  prototype_.AddCubicComponent(
      {corner.x - radii.top_right.x, corner.y},
      {corner.x - radii.top_right.x + magic_top_right.x, corner.y},
      {corner.x, corner.y + radii.top_right.y - magic_top_right.y},
      {corner.x, corner.y + radii.top_right.y});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectBottomRight(Rect rect,
                                                    RoundingRadii radii) {
  const auto magic_bottom_right = radii.bottom_right * kArcApproximationMagic;
  const auto corner = rect.GetOrigin() + rect.GetSize();
  prototype_.AddCubicComponent(
      {corner.x, corner.y - radii.bottom_right.y},
      {corner.x, corner.y - radii.bottom_right.y + magic_bottom_right.y},
      {corner.x - radii.bottom_right.x + magic_bottom_right.x, corner.y},
      {corner.x - radii.bottom_right.x, corner.y});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectBottomLeft(Rect rect,
                                                   RoundingRadii radii) {
  const auto magic_bottom_left = radii.bottom_left * kArcApproximationMagic;
  const auto corner = rect.GetOrigin() + Point{0, rect.GetHeight()};
  prototype_.AddCubicComponent(
      {corner.x + radii.bottom_left.x, corner.y},
      {corner.x + radii.bottom_left.x - magic_bottom_left.x, corner.y},
      {corner.x, corner.y - radii.bottom_left.y + magic_bottom_left.y},
      {corner.x, corner.y - radii.bottom_left.y});
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

  const Point center = oval_bounds.GetCenter();
  const Point radius = center - oval_bounds.GetOrigin();

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
  const Point c = container.GetCenter();
  const Point r = c - container.GetOrigin();
  const Point m = r * kArcApproximationMagic;

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

PathBuilder& PathBuilder::Shift(Point offset) {
  prototype_.Shift(offset);
  return *this;
}

PathBuilder& PathBuilder::SetBounds(Rect bounds) {
  prototype_.SetBounds(bounds);
  did_compute_bounds_ = true;
  return *this;
}

}  // namespace impeller
