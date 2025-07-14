// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path_builder.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/impeller/geometry/round_superellipse_param.h"
#include "flutter/third_party/skia/include/core/SkArc.h"

namespace {

inline constexpr SkPathFillType ToSkFillType(flutter::DlPathFillType dl_type) {
  switch (dl_type) {
    case impeller::FillType::kOdd:
      return SkPathFillType::kEvenOdd;
    case impeller::FillType::kNonZero:
      return SkPathFillType::kWinding;
  }
}

class BuilderReceiver : public impeller::PathReceiver {
 private:
  using Point = impeller::Point;
  using Scalar = impeller::Scalar;

 public:
  explicit BuilderReceiver(flutter::DlPathBuilder& builder)
      : builder_(builder) {}

  void MoveTo(const Point& p2, bool will_be_closed) { builder_.MoveTo(p2); }
  void LineTo(const Point& p2) { builder_.LineTo(p2); }
  void QuadTo(const Point& cp, const Point& p2) {
    builder_.QuadraticCurveTo(cp, p2);
  }
  bool ConicTo(const Point& cp, const Point& p2, Scalar weight) {
    builder_.ConicCurveTo(cp, p2, weight);
    return true;
  }
  void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) {
    builder_.CubicCurveTo(cp1, cp2, p2);
  }
  void Close() { builder_.Close(); }

 private:
  flutter::DlPathBuilder& builder_;
};

}  // namespace

namespace flutter {

DlPathBuilder& DlPathBuilder::SetFillType(DlPathFillType fill_type) {
  path_.setFillType(ToSkFillType(fill_type));
  return *this;
}

DlPathBuilder& DlPathBuilder::MoveTo(DlPoint p2) {
  path_.moveTo(p2.x, p2.y);
  return *this;
}

DlPathBuilder& DlPathBuilder::LineTo(DlPoint p2) {
  path_.lineTo(p2.x, p2.y);
  return *this;
}

DlPathBuilder& DlPathBuilder::QuadraticCurveTo(DlPoint cp, DlPoint p2) {
  path_.quadTo(cp.x, cp.y, p2.x, p2.y);
  return *this;
}

DlPathBuilder& DlPathBuilder::ConicCurveTo(DlPoint cp,
                                           DlPoint p2,
                                           DlScalar weight) {
  path_.conicTo(cp.x, cp.y, p2.x, p2.y, weight);
  return *this;
}

DlPathBuilder& DlPathBuilder::CubicCurveTo(DlPoint cp1,
                                           DlPoint cp2,
                                           DlPoint p2) {
  path_.cubicTo(cp1.x, cp1.y, cp2.x, cp2.y, p2.x, p2.y);
  return *this;
}

DlPathBuilder& DlPathBuilder::Close() {
  path_.close();
  return *this;
}

DlPathBuilder& DlPathBuilder::AddRect(const DlRect& rect) {
  path_.addRect(ToSkRect(rect));
  return *this;
}

DlPathBuilder& DlPathBuilder::AddOval(const DlRect& bounds) {
  path_.addOval(ToSkRect(bounds));
  return *this;
}

DlPathBuilder& DlPathBuilder::AddCircle(DlPoint center, DlScalar radius) {
  path_.addCircle(center.x, center.y, radius);
  return *this;
}

DlPathBuilder& DlPathBuilder::AddRoundRect(const DlRoundRect& round_rect) {
  path_.addRRect(ToSkRRect(round_rect));
  return *this;
}

DlPathBuilder& DlPathBuilder::AddRoundSuperellipse(
    const DlRoundSuperellipse& rse) {
  BuilderReceiver receiver(*this);
  impeller::RoundSuperellipseParam::MakeBoundsRadii(rse.GetBounds(),
                                                    rse.GetRadii())
      .Dispatch(receiver);
  return *this;
}

DlPathBuilder& DlPathBuilder::AddArc(const DlRect& bounds,
                                     DlDegrees start,
                                     DlDegrees sweep,
                                     bool use_center) {
  if (use_center) {
    path_.moveTo(ToSkPoint(bounds.GetCenter()));
  }
  path_.arcTo(ToSkRect(bounds), start.degrees, sweep.degrees, !use_center);
  if (use_center) {
    path_.close();
  }
  return *this;
}

DlPathBuilder& DlPathBuilder::AddPath(const DlPath& path) {
  path_.addPath(path.GetSkPath());
  return *this;
}

const DlPath DlPathBuilder::CopyPath() {
  return DlPath(path_);
}

const DlPath DlPathBuilder::TakePath() {
  DlPath path = DlPath(path_);
  path_.reset();
  return path;
}

}  // namespace flutter
