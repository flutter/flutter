// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path.h"

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/impeller/geometry/path.h"
#include "flutter/impeller/geometry/path_builder.h"

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

using Path = impeller::Path;
using PathBuilder = impeller::PathBuilder;
using FillType = impeller::FillType;
using Convexity = impeller::Convexity;
using ComponentType = impeller::Path::ComponentType;

DlPath DlPath::MakeRect(const DlRect& rect) {
  return DlPath(SkPath::Rect(ToSkRect(rect)));
}

DlPath DlPath::MakeRectLTRB(DlScalar left,
                            DlScalar top,
                            DlScalar right,
                            DlScalar bottom) {
  return DlPath(SkPath().addRect(left, top, right, bottom));
}

DlPath DlPath::MakeRectXYWH(DlScalar x,
                            DlScalar y,
                            DlScalar width,
                            DlScalar height) {
  return DlPath(SkPath().addRect(SkRect::MakeXYWH(x, y, width, height)));
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

DlPath DlPath::MakeCircle(const DlPoint& center, DlScalar radius) {
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

DlPath DlPath::MakeLine(const DlPoint& a, const DlPoint& b) {
  return DlPath(SkPath::Line(ToSkPoint(a), ToSkPoint(b)));
}

DlPath DlPath::MakePoly(const DlPoint pts[],
                        int count,
                        bool close,
                        DlPathFillType fill_type) {
  return DlPath(
      SkPath::Polygon(ToSkPoints(pts), count, close, ToSkFillType(fill_type)));
}

DlPath DlPath::MakeArc(const DlRect& bounds,
                       DlDegrees start,
                       DlDegrees end,
                       bool use_center) {
  SkPath path;
  if (use_center) {
    path.moveTo(ToSkPoint(bounds.GetCenter()));
  }
  path.arcTo(ToSkRect(bounds), start.degrees, end.degrees, !use_center);
  if (use_center) {
    path.close();
  }
  return DlPath(path);
}

const SkPath& DlPath::GetSkPath() const {
  auto& sk_path = data_->sk_path;
  auto& path = data_->path;
  if (sk_path.has_value()) {
    return sk_path.value();
  }
  if (path.has_value()) {
    sk_path.emplace(ConvertToSkiaPath(path.value()));
    if (data_->render_count >= kMaxVolatileUses) {
      sk_path.value().setIsVolatile(false);
    }
    return sk_path.value();
  }
  sk_path.emplace();
  return sk_path.value();
}

const Path& DlPath::GetPath() const {
  auto& sk_path = data_->sk_path;
  auto& path = data_->path;
  if (path.has_value()) {
    return path.value();
  }
  if (sk_path.has_value()) {
    path.emplace(ConvertToImpellerPath(sk_path.value()));
    return path.value();
  }
  path.emplace();
  return path.value();
}

void DlPath::Dispatch(DlPathReceiver& receiver) const {
  if (data_->sk_path_original) {
    auto& sk_path = data_->sk_path;
    FML_DCHECK(sk_path.has_value());
    if (sk_path.has_value()) {
      DispatchFromSkiaPath(sk_path.value(), receiver);
    }
  } else {
    auto& path = data_->path;
    FML_DCHECK(path.has_value());
    if (path.has_value()) {
      DispatchFromImpellerPath(path.value(), receiver);
    }
  }
}

void DlPath::WillRenderSkPath() const {
  if (data_->render_count >= kMaxVolatileUses) {
    auto& sk_path = data_->sk_path;
    if (sk_path.has_value()) {
      sk_path.value().setIsVolatile(false);
    }
  } else {
    data_->render_count++;
  }
}

[[nodiscard]] DlPath DlPath::WithOffset(const DlPoint& offset) const {
  if (offset.IsZero()) {
    return *this;
  }
  if (!offset.IsFinite()) {
    return DlPath();
  }
  auto& path = data_->path;
  if (path.has_value()) {
    PathBuilder builder;
    builder.AddPath(path.value());
    builder.Shift(offset);
    return DlPath(builder.TakePath());
  }
  auto& sk_path = data_->sk_path;
  if (sk_path.has_value()) {
    SkPath path = sk_path.value();
    path = path.offset(offset.x, offset.y);
    return DlPath(path);
  }
  return *this;
}

[[nodiscard]] DlPath DlPath::WithFillType(DlPathFillType type) const {
  auto& path = data_->path;
  if (path.has_value()) {
    if (path.value().GetFillType() == type) {
      return *this;
    }
    PathBuilder builder;
    builder.AddPath(path.value());
    return DlPath(builder.TakePath(type));
  }
  auto& sk_path = data_->sk_path;
  if (sk_path.has_value()) {
    SkPathFillType sk_type = ToSkFillType(type);
    if (sk_path.value().getFillType() == sk_type) {
      return *this;
    }
    SkPath path = sk_path.value();
    path.setFillType(sk_type);
    return DlPath(path);
  }
  return *this;
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

bool DlPath::IsSkRect(SkRect* rect, bool* is_closed) const {
  return GetSkPath().isRect(rect, is_closed);
}

bool DlPath::IsSkOval(SkRect* bounds) const {
  return GetSkPath().isOval(bounds);
}

bool DlPath::IsSkRRect(SkRRect* rrect) const {
  return GetSkPath().isRRect(rrect);
}

bool DlPath::Contains(const DlPoint& point) const {
  return GetSkPath().contains(point.x, point.y);
}

SkRect DlPath::GetSkBounds() const {
  return GetSkPath().getBounds();
}

DlRect DlPath::GetBounds() const {
  auto& path = data_->path;
  if (path.has_value()) {
    return path.value().GetBoundingBox().value_or(DlRect());
  }
  return ToDlRect(GetSkPath().getBounds());
}

bool DlPath::operator==(const DlPath& other) const {
  return GetSkPath() == other.GetSkPath();
}

bool DlPath::IsConverted() const {
  return data_->path.has_value() && data_->sk_path.has_value();
}

bool DlPath::IsVolatile() const {
  return GetSkPath().isVolatile();
}

bool DlPath::IsConvex() const {
  if (data_->sk_path_original) {
    auto& sk_path = data_->sk_path;
    FML_DCHECK(sk_path.has_value());
    return sk_path.has_value() && sk_path->isConvex();
  } else {
    auto& path = data_->path;
    FML_DCHECK(path.has_value());
    return path.has_value() && path->IsConvex();
  }
}

DlPath DlPath::operator+(const DlPath& other) const {
  SkPath path = GetSkPath();
  path.addPath(other.GetSkPath());
  return DlPath(path);
}

static void ReduceConic(DlPathReceiver& receiver,
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
      std::array<DlPoint, 5> points;
      impeller::ConicPathComponent conic(p1, cp, p2, weight);
      conic.SubdivideToQuadraticPoints(points);
      receiver.QuadTo(points[1], points[2]);
      receiver.QuadTo(points[3], points[4]);
    } else {
      receiver.LineTo(cp);
    }
  } else if (cp != p2) {
    receiver.LineTo(p2);
  }
}

namespace {
class SkiaPathReceiver final : public DlPathReceiver {
 public:
  void SetPathInfo(DlPathFillType fill_type, bool is_convex) override {
    sk_path_.setFillType(ToSkFillType(fill_type));
  }
  void MoveTo(const DlPoint& p2) override { sk_path_.moveTo(ToSkPoint(p2)); }
  void LineTo(const DlPoint& p2) override { sk_path_.lineTo(ToSkPoint(p2)); }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override {
    sk_path_.quadTo(ToSkPoint(cp), ToSkPoint(p2));
  }
  bool ConicTo(const DlPoint& cp, const DlPoint& p2, DlScalar weight) override {
    sk_path_.conicTo(ToSkPoint(cp), ToSkPoint(p2), weight);
    return true;
  }
  void CubicTo(const DlPoint& cp1,
               const DlPoint& cp2,
               const DlPoint& p2) override {
    sk_path_.cubicTo(ToSkPoint(cp1), ToSkPoint(cp2), ToSkPoint(p2));
  }
  void Close() override { sk_path_.close(); }

  SkPath TakePath() { return sk_path_; }

 private:
  SkPath sk_path_;
};
}  // namespace

SkPath DlPath::ConvertToSkiaPath(const Path& path) {
  SkiaPathReceiver receiver;

  DispatchFromImpellerPath(path, receiver);

  return receiver.TakePath();
}

void DlPath::DispatchFromImpellerPath(const impeller::Path& path,
                                      DlPathReceiver& receiver) {
  bool subpath_needs_close = false;
  std::optional<DlPoint> pending_moveto;

  auto resolve_moveto = [&receiver, &pending_moveto]() {
    if (pending_moveto.has_value()) {
      receiver.MoveTo(pending_moveto.value());
      pending_moveto.reset();
    }
  };

  // The Impeller Point Count is way overestimated due to duplicate
  // points between elements.
  receiver.RecommendSizes(path.GetComponentCount(), path.GetPointCount());
  std::optional<DlRect> bounds = path.GetBoundingBox();
  if (bounds.has_value()) {
    receiver.RecommendBounds(bounds.value());
  }
  receiver.SetPathInfo(path.GetFillType(), path.IsConvex());
  for (auto it = path.begin(), end = path.end(); it != end; ++it) {
    switch (it.type()) {
      case ComponentType::kContour: {
        const impeller::ContourComponent* contour = it.contour();
        FML_DCHECK(contour != nullptr);
        if (subpath_needs_close) {
          receiver.Close();
        }
        pending_moveto = contour->destination;
        subpath_needs_close = contour->IsClosed();
        break;
      }
      case ComponentType::kLinear: {
        const impeller::LinearPathComponent* linear = it.linear();
        FML_DCHECK(linear != nullptr);
        resolve_moveto();
        receiver.LineTo(linear->p2);
        break;
      }
      case ComponentType::kQuadratic: {
        const impeller::QuadraticPathComponent* quadratic = it.quadratic();
        FML_DCHECK(quadratic != nullptr);
        resolve_moveto();
        receiver.QuadTo(quadratic->cp, quadratic->p2);
        break;
      }
      case ComponentType::kConic: {
        const impeller::ConicPathComponent* conic = it.conic();
        FML_DCHECK(conic != nullptr);
        resolve_moveto();
        if (!receiver.ConicTo(conic->cp, conic->p2, conic->weight.x)) {
          ReduceConic(receiver, conic->p1, conic->cp, conic->p2,
                      conic->weight.x);
        }
        break;
      }
      case ComponentType::kCubic: {
        const impeller::CubicPathComponent* cubic = it.cubic();
        FML_DCHECK(cubic != nullptr);
        resolve_moveto();
        receiver.CubicTo(cubic->cp1, cubic->cp2, cubic->p2);
        break;
      }
    }
  }
  if (subpath_needs_close) {
    receiver.Close();
  }
}

namespace {
class ImpellerPathReceiver final : public DlPathReceiver {
 public:
  void RecommendSizes(size_t verb_count, size_t point_count) override {
    // Reserve a path size with some arbitrarily additional padding.
    builder_.Reserve(point_count + 8, verb_count + 8);
  }
  void RecommendBounds(const DlRect& bounds) override {
    builder_.SetBounds(bounds);
  }
  void SetPathInfo(DlPathFillType fill_type, bool is_convex) override {
    this->fill_type_ = fill_type;
    builder_.SetConvexity(is_convex ? Convexity::kConvex  //
                                    : Convexity::kUnknown);
  }
  void MoveTo(const DlPoint& p2) override { builder_.MoveTo(p2); }
  void LineTo(const DlPoint& p2) override { builder_.LineTo(p2); }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override {
    builder_.QuadraticCurveTo(cp, p2);
  }
  bool ConicTo(const DlPoint& cp, const DlPoint& p2, DlScalar weight) override {
    builder_.ConicCurveTo(cp, p2, weight);
    return true;
  }
  void CubicTo(const DlPoint& cp1,
               const DlPoint& cp2,
               const DlPoint& p2) override {
    builder_.CubicCurveTo(cp1, cp2, p2);
  }
  void Close() override { builder_.Close(); }

  impeller::Path TakePath() { return builder_.TakePath(fill_type_); }

 private:
  PathBuilder builder_;
  DlPathFillType fill_type_;
};
}  // namespace

Path DlPath::ConvertToImpellerPath(const SkPath& path) {
  if (path.isEmpty()) {
    return Path{};
  }

  ImpellerPathReceiver receiver;

  DispatchFromSkiaPath(path, receiver);

  return receiver.TakePath();
}

void DlPath::DispatchFromSkiaPath(const SkPath& path,
                                  DlPathReceiver& receiver) {
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

  receiver.RecommendSizes(path.countVerbs(), path.countPoints());
  receiver.RecommendBounds(ToDlRect(path.getBounds()));
  receiver.SetPathInfo(ToDlFillType(path.getFillType()), path.isConvex());
  auto verb = SkPath::Verb::kDone_Verb;
  do {
    verb = iterator.next(data.points);
    switch (verb) {
      case SkPath::kMove_Verb:
        receiver.MoveTo(ToDlPoint(data.points[0]));
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

}  // namespace flutter
