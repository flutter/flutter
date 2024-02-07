// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_builder.h"

#include <cmath>

namespace impeller {

PathBuilder::PathBuilder() {
  AddContourComponent({});
}

PathBuilder::~PathBuilder() = default;

Path PathBuilder::CopyPath(FillType fill) {
  prototype_.fill = fill;
  return Path(prototype_);
}

Path PathBuilder::TakePath(FillType fill) {
  prototype_.fill = fill;
  UpdateBounds();
  return Path(std::move(prototype_));
}

void PathBuilder::Reserve(size_t point_size, size_t verb_size) {
  prototype_.points.reserve(point_size);
  prototype_.components.reserve(verb_size);
}

PathBuilder& PathBuilder::MoveTo(Point point, bool relative) {
  current_ = relative ? current_ + point : point;
  subpath_start_ = current_;
  AddContourComponent(current_);
  return *this;
}

PathBuilder& PathBuilder::Close() {
  LineTo(subpath_start_);
  SetContourClosed(true);
  AddContourComponent(current_);
  return *this;
}

PathBuilder& PathBuilder::LineTo(Point point, bool relative) {
  point = relative ? current_ + point : point;
  AddLinearComponent(current_, point);
  current_ = point;
  return *this;
}

PathBuilder& PathBuilder::HorizontalLineTo(Scalar x, bool relative) {
  Point endpoint =
      relative ? Point{current_.x + x, current_.y} : Point{x, current_.y};
  AddLinearComponent(current_, endpoint);
  current_ = endpoint;
  return *this;
}

PathBuilder& PathBuilder::VerticalLineTo(Scalar y, bool relative) {
  Point endpoint =
      relative ? Point{current_.x, current_.y + y} : Point{current_.x, y};
  AddLinearComponent(current_, endpoint);
  current_ = endpoint;
  return *this;
}

PathBuilder& PathBuilder::QuadraticCurveTo(Point controlPoint,
                                           Point point,
                                           bool relative) {
  point = relative ? current_ + point : point;
  controlPoint = relative ? current_ + controlPoint : controlPoint;
  AddQuadraticComponent(current_, controlPoint, point);
  current_ = point;
  return *this;
}

PathBuilder& PathBuilder::SetConvexity(Convexity value) {
  prototype_.convexity = value;
  return *this;
}

PathBuilder& PathBuilder::CubicCurveTo(Point controlPoint1,
                                       Point controlPoint2,
                                       Point point,
                                       bool relative) {
  controlPoint1 = relative ? current_ + controlPoint1 : controlPoint1;
  controlPoint2 = relative ? current_ + controlPoint2 : controlPoint2;
  point = relative ? current_ + point : point;
  AddCubicComponent(current_, controlPoint1, controlPoint2, point);
  current_ = point;
  return *this;
}

PathBuilder& PathBuilder::AddQuadraticCurve(Point p1, Point cp, Point p2) {
  MoveTo(p1);
  AddQuadraticComponent(p1, cp, p2);
  return *this;
}

PathBuilder& PathBuilder::AddCubicCurve(Point p1,
                                        Point cp1,
                                        Point cp2,
                                        Point p2) {
  MoveTo(p1);
  AddCubicComponent(p1, cp1, cp2, p2);
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
  AddLinearComponent(
      {rect_origin.x + radii.top_left.x, rect_origin.y},
      {rect_origin.x + rect_size.width - radii.top_right.x, rect_origin.y});

  //----------------------------------------------------------------------------
  // Top right arc.
  //
  AddRoundedRectTopRight(rect, radii);

  //----------------------------------------------------------------------------
  // Right line.
  //
  AddLinearComponent(
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
  AddLinearComponent(
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
  AddLinearComponent(
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
  AddCubicComponent({corner.x, corner.y + radii.top_left.y},
                    {corner.x, corner.y + radii.top_left.y - magic_top_left.y},
                    {corner.x + radii.top_left.x - magic_top_left.x, corner.y},
                    {corner.x + radii.top_left.x, corner.y});
  return *this;
}

PathBuilder& PathBuilder::AddRoundedRectTopRight(Rect rect,
                                                 RoundingRadii radii) {
  const auto magic_top_right = radii.top_right * kArcApproximationMagic;
  const auto corner = rect.GetOrigin() + Point{rect.GetWidth(), 0};
  AddCubicComponent(
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
  AddCubicComponent(
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
  AddCubicComponent(
      {corner.x + radii.bottom_left.x, corner.y},
      {corner.x + radii.bottom_left.x - magic_bottom_left.x, corner.y},
      {corner.x, corner.y - radii.bottom_left.y + magic_bottom_left.y},
      {corner.x, corner.y - radii.bottom_left.y});
  return *this;
}

void PathBuilder::AddContourComponent(const Point& destination,
                                      bool is_closed) {
  auto& components = prototype_.components;
  auto& contours = prototype_.contours;
  if (components.size() > 0 &&
      components.back().type == Path::ComponentType::kContour) {
    // Never insert contiguous contours.
    contours.back() = ContourComponent(destination, is_closed);
  } else {
    contours.emplace_back(ContourComponent(destination, is_closed));
    components.emplace_back(Path::ComponentType::kContour, contours.size() - 1);
  }
  prototype_.bounds.reset();
}

void PathBuilder::AddLinearComponent(const Point& p1, const Point& p2) {
  auto& points = prototype_.points;
  auto index = points.size();
  points.emplace_back(p1);
  points.emplace_back(p2);
  prototype_.components.emplace_back(Path::ComponentType::kLinear, index);
  prototype_.bounds.reset();
}

void PathBuilder::AddQuadraticComponent(const Point& p1,
                                        const Point& cp,
                                        const Point& p2) {
  auto& points = prototype_.points;
  auto index = points.size();
  points.emplace_back(p1);
  points.emplace_back(cp);
  points.emplace_back(p2);
  prototype_.components.emplace_back(Path::ComponentType::kQuadratic, index);
  prototype_.bounds.reset();
}

void PathBuilder::AddCubicComponent(const Point& p1,
                                    const Point& cp1,
                                    const Point& cp2,
                                    const Point& p2) {
  auto& points = prototype_.points;
  auto index = points.size();
  points.emplace_back(p1);
  points.emplace_back(cp1);
  points.emplace_back(cp2);
  points.emplace_back(p2);
  prototype_.components.emplace_back(Path::ComponentType::kCubic, index);
  prototype_.bounds.reset();
}

void PathBuilder::SetContourClosed(bool is_closed) {
  prototype_.contours.back().is_closed = is_closed;
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

    AddCubicComponent(p1, cp1, cp2, p2);
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
  AddCubicComponent({c.x, c.y - r.y},        // p1
                    {c.x + m.x, c.y - r.y},  // cp1
                    {c.x + r.x, c.y - m.y},  // cp2
                    {c.x + r.x, c.y}         // p2
  );

  //----------------------------------------------------------------------------
  // Bottom right arc.
  //
  AddCubicComponent({c.x + r.x, c.y},        // p1
                    {c.x + r.x, c.y + m.y},  // cp1
                    {c.x + m.x, c.y + r.y},  // cp2
                    {c.x, c.y + r.y}         // p2
  );

  //----------------------------------------------------------------------------
  // Bottom left arc.
  //
  AddCubicComponent({c.x, c.y + r.y},        // p1
                    {c.x - m.x, c.y + r.y},  // cp1
                    {c.x - r.x, c.y + m.y},  // cp2
                    {c.x - r.x, c.y}         // p2
  );

  //----------------------------------------------------------------------------
  // Top left arc.
  //
  AddCubicComponent({c.x - r.x, c.y},        // p1
                    {c.x - r.x, c.y - m.y},  // cp1
                    {c.x - m.x, c.y - r.y},  // cp2
                    {c.x, c.y - r.y}         // p2
  );

  Close();

  return *this;
}

PathBuilder& PathBuilder::AddLine(const Point& p1, const Point& p2) {
  MoveTo(p1);
  AddLinearComponent(p1, p2);
  return *this;
}

PathBuilder& PathBuilder::AddPath(const Path& path) {
  auto linear = [&](size_t index, const LinearPathComponent& l) {
    AddLinearComponent(l.p1, l.p2);
  };
  auto quadratic = [&](size_t index, const QuadraticPathComponent& q) {
    AddQuadraticComponent(q.p1, q.cp, q.p2);
  };
  auto cubic = [&](size_t index, const CubicPathComponent& c) {
    AddCubicComponent(c.p1, c.cp1, c.cp2, c.p2);
  };
  auto move = [&](size_t index, const ContourComponent& m) {
    AddContourComponent(m.destination);
  };
  path.EnumerateComponents(linear, quadratic, cubic, move);
  return *this;
}

PathBuilder& PathBuilder::Shift(Point offset) {
  for (auto& point : prototype_.points) {
    point += offset;
  }
  for (auto& contour : prototype_.contours) {
    contour.destination += offset;
  }
  prototype_.bounds.reset();
  return *this;
}

PathBuilder& PathBuilder::SetBounds(Rect bounds) {
  prototype_.bounds = bounds;
  return *this;
}

void PathBuilder::UpdateBounds() {
  if (!prototype_.bounds.has_value()) {
    auto min_max = GetMinMaxCoveragePoints();
    if (!min_max.has_value()) {
      prototype_.bounds.reset();
      return;
    }
    auto min = min_max->first;
    auto max = min_max->second;
    const auto difference = max - min;
    prototype_.bounds =
        Rect::MakeXYWH(min.x, min.y, difference.x, difference.y);
  }
}

std::optional<std::pair<Point, Point>> PathBuilder::GetMinMaxCoveragePoints()
    const {
  auto& points = prototype_.points;

  if (points.empty()) {
    return std::nullopt;
  }

  std::optional<Point> min, max;

  auto clamp = [&min, &max](const Point& point) {
    if (min.has_value()) {
      min = min->Min(point);
    } else {
      min = point;
    }

    if (max.has_value()) {
      max = max->Max(point);
    } else {
      max = point;
    }
  };

  for (const auto& component : prototype_.components) {
    switch (component.type) {
      case Path::ComponentType::kLinear: {
        auto* linear = reinterpret_cast<const LinearPathComponent*>(
            &points[component.index]);
        clamp(linear->p1);
        clamp(linear->p2);
        break;
      }
      case Path::ComponentType::kQuadratic:
        for (const auto& extrema :
             reinterpret_cast<const QuadraticPathComponent*>(
                 &points[component.index])
                 ->Extrema()) {
          clamp(extrema);
        }
        break;
      case Path::ComponentType::kCubic:
        for (const auto& extrema : reinterpret_cast<const CubicPathComponent*>(
                                       &points[component.index])
                                       ->Extrema()) {
          clamp(extrema);
        }
        break;
      case Path::ComponentType::kContour:
        break;
    }
  }

  if (!min.has_value() || !max.has_value()) {
    return std::nullopt;
  }

  return std::make_pair(min.value(), max.value());
}

}  // namespace impeller
