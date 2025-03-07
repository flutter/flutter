// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_path.h"

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/impeller/geometry/path_builder.h"
#include "impeller/geometry/path.h"

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

SkPath DlPath::ConvertToSkiaPath(const Path& path) {
  SkPath sk_path;

  DlPathReceiver receiver{
      .path_info =
          [&sk_path](DlPathFillType fill_type, bool is_convex) {
            sk_path.setFillType(ToSkFillType(fill_type));
          },
      .move_to =
          [&sk_path](const DlPoint& p2) { sk_path.moveTo(ToSkPoint(p2)); },
      .line_to =
          [&sk_path](const DlPoint& p2) { sk_path.lineTo(ToSkPoint(p2)); },
      .quad_to =
          [&sk_path](const DlPoint& cp, const DlPoint& p2) {
            sk_path.quadTo(ToSkPoint(cp), ToSkPoint(p2));
          },
      .conic_to =
          [&sk_path](const DlPoint& cp, const DlPoint& p2, DlScalar weight) {
            sk_path.conicTo(ToSkPoint(cp), ToSkPoint(p2), weight);
            return true;
          },
      .cubic_to =
          [&sk_path](const DlPoint& cp1,  //
                     const DlPoint& cp2,  //
                     const DlPoint& p2) {
            sk_path.cubicTo(ToSkPoint(cp1), ToSkPoint(cp2), ToSkPoint(p2));
          },
      .close = [&sk_path]() { sk_path.close(); },
  };

  DispatchFromImpellerPath(path, receiver);

  return sk_path;
}

void DlPath::DispatchFromImpellerPath(const impeller::Path& path,
                                      DlPathReceiver& receiver) {
  bool subpath_needs_close = false;
  std::optional<DlPoint> pending_moveto;

  auto resolve_moveto = [&receiver, &pending_moveto]() {
    if (pending_moveto.has_value()) {
      receiver.move_to(pending_moveto.value());
      pending_moveto.reset();
    }
  };

  receiver.recommend_size(path.GetComponentCount(), path.GetPointCount());
  std::optional<DlRect> bounds = path.GetBoundingBox();
  if (bounds.has_value()) {
    receiver.recommend_bounds(bounds.value());
  }
  receiver.path_info(path.GetFillType(), path.IsConvex());
  for (auto it = path.begin(), end = path.end(); it != end; ++it) {
    switch (it.type()) {
      case ComponentType::kContour: {
        const impeller::ContourComponent* contour = it.contour();
        FML_DCHECK(contour != nullptr);
        if (subpath_needs_close) {
          receiver.close();
        }
        pending_moveto = contour->destination;
        subpath_needs_close = contour->IsClosed();
        break;
      }
      case ComponentType::kLinear: {
        const impeller::LinearPathComponent* linear = it.linear();
        FML_DCHECK(linear != nullptr);
        resolve_moveto();
        receiver.line_to(linear->p2);
        break;
      }
      case ComponentType::kQuadratic: {
        const impeller::QuadraticPathComponent* quadratic = it.quadratic();
        FML_DCHECK(quadratic != nullptr);
        resolve_moveto();
        receiver.quad_to(quadratic->cp, quadratic->p2);
        break;
      }
      case ComponentType::kConic: {
        const impeller::ConicPathComponent* conic = it.conic();
        FML_DCHECK(conic != nullptr);
        resolve_moveto();
        receiver.conic_to(conic->cp, conic->p2, conic->weight.x);
        break;
      }
      case ComponentType::kCubic: {
        const impeller::CubicPathComponent* cubic = it.cubic();
        FML_DCHECK(cubic != nullptr);
        resolve_moveto();
        receiver.cubic_to(cubic->cp1, cubic->cp2, cubic->p2);
        break;
      }
    }
  }
  if (subpath_needs_close) {
    receiver.close();
  }
}

Path DlPath::ConvertToImpellerPath(const SkPath& path) {
  if (path.isEmpty()) {
    return Path{};
  }

  PathBuilder builder;
  DlPathFillType path_fill_type;

  DlPathReceiver receiver{
      .recommend_size =
          [&builder](size_t verb_count, size_t point_count) {
            // Reserve a path size with some arbitrarily additional padding.
            builder.Reserve(point_count + 8, verb_count + 8);
          },
      .recommend_bounds =
          [&builder](const DlRect& bounds) { builder.SetBounds(bounds); },
      .path_info =
          [&builder, &path_fill_type](DlPathFillType fill_type,
                                      bool is_convex) {
            path_fill_type = fill_type;
            builder.SetConvexity(is_convex ? Convexity::kConvex
                                           : Convexity::kUnknown);
          },
      .move_to = [&builder](const DlPoint& p2) { builder.MoveTo(p2); },
      .line_to = [&builder](const DlPoint& p2) { builder.LineTo(p2); },
      .quad_to =
          [&builder](const DlPoint& cp, const DlPoint& p2) {  //
            builder.QuadraticCurveTo(cp, p2);
          },
      // .conic_to = ... for legacy compatibility we let the SkPath dispatcher
      //                 convert conics to quads until we update Impeller for
      //                 full support of rational quadratics
      .cubic_to =
          [&builder](const DlPoint& cp1,   //
                     const DlPoint& cp2,   //
                     const DlPoint& p2) {  //
            builder.CubicCurveTo(cp1, cp2, p2);
          },
      .close = [&builder]() { builder.Close(); },
  };

  DispatchFromSkiaPath(path, receiver);

  return builder.TakePath(path_fill_type);
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

  receiver.recommend_size(path.countVerbs(), path.countPoints());
  receiver.recommend_bounds(ToDlRect(path.getBounds()));
  receiver.path_info(ToDlFillType(path.getFillType()), path.isConvex());
  auto verb = SkPath::Verb::kDone_Verb;
  do {
    verb = iterator.next(data.points);
    switch (verb) {
      case SkPath::kMove_Verb:
        receiver.move_to(ToDlPoint(data.points[0]));
        break;
      case SkPath::kLine_Verb:
        receiver.line_to(ToDlPoint(data.points[1]));
        break;
      case SkPath::kQuad_Verb:
        receiver.quad_to(ToDlPoint(data.points[1]), ToDlPoint(data.points[2]));
        break;
      case SkPath::kConic_Verb:
        if (receiver.conic_to(ToDlPoint(data.points[1]),
                              ToDlPoint(data.points[2]),
                              iterator.conicWeight())) {
          // The conic parameters were understood and accepted, we are done
          // with this path segment.
          break;
        }

        // We might eventually have conic conversion math that deals with
        // degenerate conics gracefully (or have all receivers just handle
        // them directly). But, until then, we will just convert them to a
        // pair of quads and accept the results as "close enough".
        if (data.points[0] != data.points[1]) {
          if (data.points[1] != data.points[2]) {
            std::array<DlPoint, 5> points;
            impeller::ConicPathComponent conic(
                ToDlPoint(data.points[0]), ToDlPoint(data.points[1]),
                ToDlPoint(data.points[2]), iterator.conicWeight());
            conic.SubdivideToQuadraticPoints(points);
            receiver.quad_to(points[1], points[2]);
            receiver.quad_to(points[3], points[4]);
          } else {
            receiver.line_to(ToDlPoint(data.points[1]));
          }
        } else if (data.points[1] != data.points[2]) {
          receiver.line_to(ToDlPoint(data.points[2]));
        }
        break;
      case SkPath::kCubic_Verb:
        receiver.cubic_to(ToDlPoint(data.points[1]),  //
                          ToDlPoint(data.points[2]),  //
                          ToDlPoint(data.points[3]));
        break;
      case SkPath::kClose_Verb:
        receiver.close();
        break;
      case SkPath::kDone_Verb:
        break;
    }
  } while (verb != SkPath::Verb::kDone_Verb);
}

}  // namespace flutter
