// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "path_builder.h"

namespace impeller {

static const Scalar kArcApproximationMagic = 0.551915024494;

PathBuilder::PathBuilder() = default;

PathBuilder::~PathBuilder() = default;

Path PathBuilder::CopyPath(FillType fill) const {
  auto path = prototype_;
  path.SetFillType(fill);
  return path;
}

Path PathBuilder::TakePath(FillType fill) {
  auto path = std::move(prototype_);
  path.SetFillType(fill);
  return path;
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

  auto tl = rect.origin;
  auto bl = rect.origin + Point{0.0, rect.size.height};
  auto br = rect.origin + Point{rect.size.width, rect.size.height};
  auto tr = rect.origin + Point{rect.size.width, 0.0};

  prototype_.AddLinearComponent(tl, tr)
      .AddLinearComponent(tr, br)
      .AddLinearComponent(br, bl)
      .AddLinearComponent(bl, tl);

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

  const auto magic_top_right = radii.top_right * kArcApproximationMagic;
  const auto magic_bottom_right = radii.bottom_right * kArcApproximationMagic;
  const auto magic_bottom_left = radii.bottom_left * kArcApproximationMagic;
  const auto magic_top_left = radii.top_left * kArcApproximationMagic;

  //----------------------------------------------------------------------------
  // Top line.
  //
  prototype_.AddLinearComponent(
      {rect.origin.x + radii.top_left.x, rect.origin.y},
      {rect.origin.x + rect.size.width - radii.top_right.x, rect.origin.y});

  //----------------------------------------------------------------------------
  // Top right arc.
  //
  prototype_.AddCubicComponent(
      {rect.origin.x + rect.size.width - radii.top_right.x, rect.origin.y},
      {rect.origin.x + rect.size.width - radii.top_right.x + magic_top_right.x,
       rect.origin.y},
      {rect.origin.x + rect.size.width,
       rect.origin.y + radii.top_right.y - magic_top_right.y},
      {rect.origin.x + rect.size.width, rect.origin.y + radii.top_right.y});

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
  prototype_.AddCubicComponent(
      {rect.origin.x + radii.bottom_left.x, rect.origin.y + rect.size.height},
      {rect.origin.x + radii.bottom_left.x - magic_bottom_left.x,
       rect.origin.y + rect.size.height},
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottom_left.y +
                          magic_bottom_left.y},
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottom_left.y});

  //----------------------------------------------------------------------------
  // Left line.
  //
  prototype_.AddLinearComponent(
      {rect.origin.x, rect.origin.y + rect.size.height - radii.bottom_left.y},
      {rect.origin.x, rect.origin.y + radii.top_left.y});

  //----------------------------------------------------------------------------
  // Top left arc.
  //
  prototype_.AddCubicComponent(
      {rect.origin.x, rect.origin.y + radii.top_left.y},
      {rect.origin.x, rect.origin.y + radii.top_left.y - magic_top_left.y},
      {rect.origin.x + radii.top_left.x - magic_top_left.x, rect.origin.y},
      {rect.origin.x + radii.top_left.x, rect.origin.y});

  return *this;
}

PathBuilder& PathBuilder::AddOval(const Rect& container) {
  const Point r = {container.size.width * 0.5f, container.size.height * 0.5f};
  const Point c = {container.origin.x + (container.size.width * 0.5f),
                   container.origin.y + (container.size.height * 0.5f)};
  const Point m = {kArcApproximationMagic * r.x, kArcApproximationMagic * r.y};

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

  return *this;
}

PathBuilder& PathBuilder::AddLine(const Point& p1, const Point& p2) {
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
  path.EnumerateComponents(linear, quadratic, cubic);
  return *this;
}

}  // namespace impeller
