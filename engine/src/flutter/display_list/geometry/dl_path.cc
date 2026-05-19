// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/display_list/geometry/dl_path_builder.h"

namespace {
inline constexpr flutter::DlPathFillType ToDlFillType(SkPathFillType sk_type) {
  switch (sk_type) {
    case SkPathFillType::kEvenOdd:
      return impeller::FillType::kOdd;
    case SkPathFillType::kWinding:
      return impeller::FillType::kNonZero;
    case SkPathFillType::kInverseEvenOdd:
    case SkPathFillType::kInverseWinding:
      FML_UNREACHABLE();
  }
}

inline constexpr SkPathFillType ToSkFillType(flutter::DlPathFillType dl_type) {
  switch (dl_type) {
    case impeller::FillType::kOdd:
      return SkPathFillType::kEvenOdd;
    case impeller::FillType::kNonZero:
      return SkPathFillType::kWinding;
  }
}
}  // namespace

namespace flutter {

using FillType = impeller::FillType;
using Convexity = impeller::Convexity;

DlPath DlPath::MakeRect(const DlRect& rect) {
  return DlPath(SkPath::Rect(ToSkRect(rect)));
}

DlPath DlPath::MakeRectLTRB(DlScalar left,
                            DlScalar top,
                            DlScalar right,
                            DlScalar bottom) {
  return DlPath(SkPath::Rect(SkRect::MakeLTRB(left, top, right, bottom)));
}

DlPath DlPath::MakeRectXYWH(DlScalar x,
                            DlScalar y,
                            DlScalar width,
                            DlScalar height) {
  return DlPath(SkPath::Rect(SkRect::MakeXYWH(x, y, width, height)));
}

DlPath DlPath::MakeOval(const DlRect& bounds) {
  return DlPath(SkPath::Oval(ToSkRect(bounds)));
}

DlPath DlPath::MakeOvalLTRB(DlScalar left,
                            DlScalar top,
                            DlScalar right,
                            DlScalar bottom) {
  return DlPath(SkPath::Oval(SkRect::MakeLTRB(left, top, right, bottom)));
}

DlPath DlPath::MakeCircle(const DlPoint center, DlScalar radius) {
  return DlPath(SkPath::Circle(center.x, center.y, radius));
}

DlPath DlPath::MakeRoundRect(const DlRoundRect& rrect) {
  return DlPath(SkPath::RRect(ToSkRRect(rrect)));
}

DlPath DlPath::MakeRoundRectXY(const DlRect& rect,
                               DlScalar x_radius,
                               DlScalar y_radius,
                               bool counter_clock_wise) {
  return DlPath(SkPath::RRect(
      ToSkRect(rect), x_radius, y_radius,
      counter_clock_wise ? SkPathDirection::kCCW : SkPathDirection::kCW));
}

DlPath DlPath::MakeRoundSuperellipse(const DlRoundSuperellipse& rse) {
  return DlPathBuilder{}.AddRoundSuperellipse(rse).TakePath();
}

DlPath DlPath::MakeLine(const DlPoint a, const DlPoint b) {
  return DlPath(SkPath::Line(ToSkPoint(a), ToSkPoint(b)));
}

DlPath DlPath::MakePoly(const DlPoint pts[],
                        int count,
                        bool close,
                        DlPathFillType fill_type) {
  return DlPath(SkPath::Polygon({ToSkPoints(pts), count}, close,
                                ToSkFillType(fill_type)));
}

DlPath DlPath::MakeArc(const DlRect& bounds,
                       DlDegrees start,
                       DlDegrees sweep,
                       bool use_center) {
  SkPathBuilder path;
  if (use_center) {
    path.moveTo(ToSkPoint(bounds.GetCenter()));
  }
  path.arcTo(ToSkRect(bounds), start.degrees, sweep.degrees, !use_center);
  if (use_center) {
    path.close();
  }
  return DlPath(path.detach());
}

const SkPath& DlPath::GetSkPath() const {
  return data_->sk_path;
}

void DlPath::Dispatch(DlPathReceiver& receiver) const {
  const SkPath& path = data_->sk_path;
  if (path.isEmpty()) {
    return;
  }

  auto iterator = SkPath::Iter(path, false);

  struct PathData {
    union {
      SkPoint points[4];
    };
  };

  PathData data;

  auto verb = SkPath::Verb::kDone_Verb;
  do {
    verb = iterator.next(data.points);
    switch (verb) {
      case SkPath::kMove_Verb:
        receiver.MoveTo(ToDlPoint(data.points[0]), iterator.isClosedContour());
        break;
      case SkPath::kLine_Verb:
        receiver.LineTo(ToDlPoint(data.points[1]));
        break;
      case SkPath::kQuad_Verb:
        receiver.QuadTo(ToDlPoint(data.points[1]), ToDlPoint(data.points[2]));
        break;
      case SkPath::kConic_Verb:
        if (!receiver.ConicTo(ToDlPoint(data.points[1]),
                              ToDlPoint(data.points[2]),
                              iterator.conicWeight())) {
          ReduceConic(receiver,                   //
                      ToDlPoint(data.points[0]),  //
                      ToDlPoint(data.points[1]),  //
                      ToDlPoint(data.points[2]),  //
                      iterator.conicWeight());
        }
        break;
      case SkPath::kCubic_Verb:
        receiver.CubicTo(ToDlPoint(data.points[1]),  //
                         ToDlPoint(data.points[2]),  //
                         ToDlPoint(data.points[3]));
        break;
      case SkPath::kClose_Verb:
        receiver.Close();
        break;
      case SkPath::kDone_Verb:
        break;
    }
  } while (verb != SkPath::Verb::kDone_Verb);
}

void DlPath::WillRenderSkPath() const {
  uint32_t count = data_->render_count;
  if (count <= kMaxVolatileUses) {
    if (count == kMaxVolatileUses) {
      data_->sk_path.setIsVolatile(false);
    }
    data_->render_count = ++count;
  }
}

[[nodiscard]] DlPath DlPath::WithOffset(const DlPoint offset) const {
  if (offset.IsZero()) {
    return *this;
  }
  if (!offset.IsFinite()) {
    return DlPath();
  }
  return DlPath(data_->sk_path.makeOffset(offset.x, offset.y));
}

[[nodiscard]] DlPath DlPath::WithFillType(DlPathFillType type) const {
  SkPathFillType sk_type = ToSkFillType(type);
  if (data_->sk_path.getFillType() == sk_type) {
    return *this;
  }
  SkPath path = data_->sk_path;
  path.setFillType(sk_type);
  return DlPath(path);
}

bool DlPath::IsEmpty() const {
  return GetSkPath().isEmpty();
}

bool DlPath::IsRect(DlRect* rect, bool* is_closed) const {
  return GetSkPath().isRect(ToSkRect(rect), is_closed);
}

bool DlPath::IsOval(DlRect* bounds) const {
  return GetSkPath().isOval(ToSkRect(bounds));
}

bool DlPath::IsLine(DlPoint* start, DlPoint* end) const {
  SkPoint sk_points[2];
  if (GetSkPath().isLine(sk_points)) {
    *start = ToDlPoint(sk_points[0]);
    *end = ToDlPoint(sk_points[1]);
    return true;
  }
  return false;
}

bool DlPath::IsRoundRect(DlRoundRect* rrect) const {
  SkRRect sk_rrect;
  bool ret = GetSkPath().isRRect(rrect ? &sk_rrect : nullptr);
  if (rrect) {
    *rrect = ToDlRoundRect(sk_rrect);
  }
  return ret;
}

bool DlPath::Contains(const DlPoint point) const {
  return GetSkPath().contains(point.x, point.y);
}

DlPathFillType DlPath::GetFillType() const {
  return ToDlFillType(GetSkPath().getFillType());
}

DlRect DlPath::GetBounds() const {
  return ToDlRect(GetSkPath().getBounds());
}

bool DlPath::operator==(const DlPath& other) const {
  return GetSkPath() == other.GetSkPath();
}

bool DlPath::IsVolatile() const {
  return GetSkPath().isVolatile();
}

bool DlPath::IsConvex() const {
  return data_->sk_path.isConvex();
}

DlPath DlPath::operator+(const DlPath& other) const {
  SkPathBuilder path = SkPathBuilder(GetSkPath());
  path.addPath(other.GetSkPath());
  return DlPath(path.detach());
}

void DlPath::ReduceConic(DlPathReceiver& receiver,
                         const DlPoint& p1,
                         const DlPoint& cp,
                         const DlPoint& p2,
                         DlScalar weight) {
  // We might eventually have conic conversion math that deals with
  // degenerate conics gracefully (or have all receivers just handle
  // them directly). But, until then, we will just convert them to a
  // pair of quads and accept the results as "close enough".
  if (p1 != cp) {
    if (cp != p2) {
      FML_DCHECK(std::isfinite(weight) && weight > 0);

      // Observe that scale will always be smaller than 1 because weight > 0.
      const DlScalar scale = 1.0f / (1.0f + weight);

      // The subdivided control points below are the sums of the following
      // three terms. Because the terms are multiplied by something <1, and
      // the resulting control points lie within the control points of the
      // original then the terms and the sums below will not overflow.
      // Note that weight * scale approaches 1 as weight becomes very large.
      DlPoint tp1 = p1 * scale;
      DlPoint tcp = cp * (weight * scale);
      DlPoint tp2 = p2 * scale;

      // Calculate the subdivided control points
      DlPoint sub_cp1 = tp1 + tcp;
      DlPoint sub_cp2 = tcp + tp2;

      // The middle point shared by the 2 sub-divisions, the interpolation of
      // the original curve at its halfway point.
      DlPoint sub_mid = (tp1 + tcp + tcp + tp2) * 0.5f;

      FML_DCHECK(sub_cp1.IsFinite() &&  //
                 sub_mid.IsFinite() &&  //
                 sub_cp2.IsFinite());

      receiver.QuadTo(sub_cp1, sub_mid);
      receiver.QuadTo(sub_cp2, p2);

      // Update w.
      // Currently this method only subdivides a single time directly to 2
      // quadratics, but if we eventually want to keep the weights for further
      // subdivision, this was the code that did it in Skia:
      // sub_w1 = sub_w2 = SkScalarSqrt(SK_ScalarHalf + w * SK_ScalarHalf)
    } else {
      receiver.LineTo(cp);
    }
  } else if (cp != p2) {
    receiver.LineTo(p2);
  }
}

}  // namespace flutter
