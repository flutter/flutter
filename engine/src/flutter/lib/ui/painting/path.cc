// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/path.h"

#include <cmath>

#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/lib/ui/floating_point.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace flutter {

typedef CanvasPath Path;

IMPLEMENT_WRAPPERTYPEINFO(ui, Path);

CanvasPath::CanvasPath() {
  sk_path_.setIsVolatile(
      !UIDartState::Current()->IsDeterministicRenderingEnabled());
  resetVolatility();
}

CanvasPath::~CanvasPath() = default;

void CanvasPath::resetVolatility() {
  dl_path_.reset();
}

int CanvasPath::getFillType() {
  return static_cast<int>(sk_path_.fillType());
}

void CanvasPath::setFillType(int fill_type) {
  sk_path_.setFillType(static_cast<SkPathFillType>(fill_type));
  resetVolatility();
}

void CanvasPath::moveTo(double x, double y) {
  sk_path_.moveTo(SafeNarrow(x), SafeNarrow(y));
  resetVolatility();
}

void CanvasPath::relativeMoveTo(double x, double y) {
  sk_path_.rMoveTo({SafeNarrow(x), SafeNarrow(y)});
  resetVolatility();
}

void CanvasPath::lineTo(double x, double y) {
  sk_path_.lineTo({SafeNarrow(x), SafeNarrow(y)});
  resetVolatility();
}

void CanvasPath::relativeLineTo(double x, double y) {
  sk_path_.rLineTo({SafeNarrow(x), SafeNarrow(y)});
  resetVolatility();
}

void CanvasPath::quadraticBezierTo(double x1, double y1, double x2, double y2) {
  sk_path_.quadTo({SafeNarrow(x1), SafeNarrow(y1)},
                  {SafeNarrow(x2), SafeNarrow(y2)});
  resetVolatility();
}

void CanvasPath::relativeQuadraticBezierTo(double x1,
                                           double y1,
                                           double x2,
                                           double y2) {
  sk_path_.rQuadTo({SafeNarrow(x1), SafeNarrow(y1)},
                   {SafeNarrow(x2), SafeNarrow(y2)});
  resetVolatility();
}

void CanvasPath::cubicTo(double x1,
                         double y1,
                         double x2,
                         double y2,
                         double x3,
                         double y3) {
  sk_path_.cubicTo({SafeNarrow(x1), SafeNarrow(y1)},
                   {SafeNarrow(x2), SafeNarrow(y2)},
                   {SafeNarrow(x3), SafeNarrow(y3)});
  resetVolatility();
}

void CanvasPath::relativeCubicTo(double x1,
                                 double y1,
                                 double x2,
                                 double y2,
                                 double x3,
                                 double y3) {
  sk_path_.rCubicTo({SafeNarrow(x1), SafeNarrow(y1)},
                    {SafeNarrow(x2), SafeNarrow(y2)},
                    {SafeNarrow(x3), SafeNarrow(y3)});
  resetVolatility();
}

void CanvasPath::conicTo(double x1, double y1, double x2, double y2, double w) {
  sk_path_.conicTo({SafeNarrow(x1), SafeNarrow(y1)},
                   {SafeNarrow(x2), SafeNarrow(y2)}, SafeNarrow(w));
  resetVolatility();
}

void CanvasPath::relativeConicTo(double x1,
                                 double y1,
                                 double x2,
                                 double y2,
                                 double w) {
  sk_path_.rConicTo({SafeNarrow(x1), SafeNarrow(y1)},
                    {SafeNarrow(x2), SafeNarrow(y2)}, SafeNarrow(w));
  resetVolatility();
}

void CanvasPath::arcTo(double left,
                       double top,
                       double right,
                       double bottom,
                       double startAngle,
                       double sweepAngle,
                       bool forceMoveTo) {
  sk_path_.arcTo(SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                                  SafeNarrow(right), SafeNarrow(bottom)),
                 SafeNarrow(startAngle) * 180.0f / static_cast<float>(M_PI),
                 SafeNarrow(sweepAngle) * 180.0f / static_cast<float>(M_PI),
                 forceMoveTo);
  resetVolatility();
}

void CanvasPath::arcToPoint(double arcEndX,
                            double arcEndY,
                            double radiusX,
                            double radiusY,
                            double xAxisRotation,
                            bool isLargeArc,
                            bool isClockwiseDirection) {
  const auto arcSize = isLargeArc ? SkPathBuilder::ArcSize::kLarge_ArcSize
                                  : SkPathBuilder::ArcSize::kSmall_ArcSize;
  const auto direction =
      isClockwiseDirection ? SkPathDirection::kCW : SkPathDirection::kCCW;

  sk_path_.arcTo({SafeNarrow(radiusX), SafeNarrow(radiusY)},
                 SafeNarrow(xAxisRotation), arcSize, direction,
                 {SafeNarrow(arcEndX), SafeNarrow(arcEndY)});
  resetVolatility();
}

void CanvasPath::relativeArcToPoint(double arcEndDeltaX,
                                    double arcEndDeltaY,
                                    double radiusX,
                                    double radiusY,
                                    double xAxisRotation,
                                    bool isLargeArc,
                                    bool isClockwiseDirection) {
  const auto arcSize = isLargeArc ? SkPathBuilder::ArcSize::kLarge_ArcSize
                                  : SkPathBuilder::ArcSize::kSmall_ArcSize;
  const auto direction =
      isClockwiseDirection ? SkPathDirection::kCW : SkPathDirection::kCCW;
  sk_path_.rArcTo({SafeNarrow(radiusX), SafeNarrow(radiusY)},
                  SafeNarrow(xAxisRotation), arcSize, direction,
                  {SafeNarrow(arcEndDeltaX), SafeNarrow(arcEndDeltaY)});
  resetVolatility();
}

void CanvasPath::addRect(double left, double top, double right, double bottom) {
  sk_path_.addRect(SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                                    SafeNarrow(right), SafeNarrow(bottom)));
  resetVolatility();
}

void CanvasPath::addOval(double left, double top, double right, double bottom) {
  sk_path_.addOval(SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                                    SafeNarrow(right), SafeNarrow(bottom)));
  resetVolatility();
}

void CanvasPath::addArc(double left,
                        double top,
                        double right,
                        double bottom,
                        double startAngle,
                        double sweepAngle) {
  sk_path_.addArc(SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                                   SafeNarrow(right), SafeNarrow(bottom)),
                  SafeNarrow(startAngle) * 180.0f / static_cast<float>(M_PI),
                  SafeNarrow(sweepAngle) * 180.0f / static_cast<float>(M_PI));
  resetVolatility();
}

void CanvasPath::addPolygon(const tonic::Float32List& points, bool close) {
  SkSpan<const SkPoint> ptsSpan = {
      reinterpret_cast<const SkPoint*>(points.data()),
      points.num_elements() / 2};
  sk_path_.addPolygon(ptsSpan, close);
  resetVolatility();
}

void CanvasPath::addRRect(const RRect& rrect) {
  sk_path_.addRRect(ToSkRRect(rrect.rrect));
  resetVolatility();
}

void CanvasPath::addRSuperellipse(const RSuperellipse* rsuperellipse) {
  DlPathBuilder builder;
  builder.AddRoundSuperellipse(DlRoundSuperellipse::MakeRectRadii(
      rsuperellipse->bounds(), rsuperellipse->radii()));
  sk_path_.addPath(builder.TakePath().GetSkPath(), SkPath::kAppend_AddPathMode);

  resetVolatility();
}

void CanvasPath::addPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(ToDart("Path.addPath called with non-genuine Path."));
    return;
  }
  sk_path_.addPath(path->path().GetSkPath(), SafeNarrow(dx), SafeNarrow(dy),
                   SkPath::kAppend_AddPathMode);
  resetVolatility();
}

void CanvasPath::addPathWithMatrix(CanvasPath* path,
                                   double dx,
                                   double dy,
                                   Dart_Handle matrix4_handle) {
  tonic::Float64List matrix4(matrix4_handle);

  if (!path) {
    matrix4.Release();
    Dart_ThrowException(
        ToDart("Path.addPathWithMatrix called with non-genuine Path."));
    return;
  }

  SkMatrix matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  matrix.setTranslateX(matrix.getTranslateX() + SafeNarrow(dx));
  matrix.setTranslateY(matrix.getTranslateY() + SafeNarrow(dy));
  sk_path_.addPath(path->path().GetSkPath(), matrix,
                   SkPath::kAppend_AddPathMode);
  resetVolatility();
}

void CanvasPath::extendWithPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Path.extendWithPath called with non-genuine Path."));
    return;
  }
  sk_path_.addPath(path->path().GetSkPath(), SafeNarrow(dx), SafeNarrow(dy),
                   SkPath::kExtend_AddPathMode);
  resetVolatility();
}

void CanvasPath::extendWithPathAndMatrix(CanvasPath* path,
                                         double dx,
                                         double dy,
                                         Dart_Handle matrix4_handle) {
  tonic::Float64List matrix4(matrix4_handle);

  if (!path) {
    matrix4.Release();
    Dart_ThrowException(
        ToDart("Path.addPathWithMatrix called with non-genuine Path."));
    return;
  }

  SkMatrix matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  matrix.setTranslateX(matrix.getTranslateX() + SafeNarrow(dx));
  matrix.setTranslateY(matrix.getTranslateY() + SafeNarrow(dy));
  sk_path_.addPath(path->path().GetSkPath(), matrix,
                   SkPath::kExtend_AddPathMode);
  resetVolatility();
}

void CanvasPath::close() {
  sk_path_.close();
  resetVolatility();
}

void CanvasPath::reset() {
  sk_path_.reset();
  resetVolatility();
}

bool CanvasPath::contains(double x, double y) {
  return sk_path_.contains({SafeNarrow(x), SafeNarrow(y)});
}

void CanvasPath::shift(Dart_Handle path_handle, double dx, double dy) {
  fml::RefPtr<CanvasPath> path = Create(path_handle);
  path->sk_path_ = sk_path_;
  path->sk_path_.offset(SafeNarrow(dx), SafeNarrow(dy));
}

void CanvasPath::transform(Dart_Handle path_handle,
                           Dart_Handle matrix4_handle) {
  tonic::Float64List matrix4(matrix4_handle);
  auto sk_matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  fml::RefPtr<CanvasPath> path = Create(path_handle);
  path->sk_path_ = sk_path_;
  path->sk_path_.transform(sk_matrix);
}

tonic::Float32List CanvasPath::getBounds() {
  tonic::Float32List rect(Dart_NewTypedData(Dart_TypedData_kFloat32, 4));
  const SkRect& bounds = sk_path_.computeFiniteBounds().value_or(SkRect());
  rect[0] = bounds.left();
  rect[1] = bounds.top();
  rect[2] = bounds.right();
  rect[3] = bounds.bottom();
  return rect;
}

bool CanvasPath::op(CanvasPath* path1, CanvasPath* path2, int operation) {
  std::optional<SkPath> result =
      Op(path1->path().GetSkPath(), path2->path().GetSkPath(),
         static_cast<SkPathOp>(operation));
  if (result) {
    sk_path_ = result.value();
    resetVolatility();
    return true;
  }
  return false;
}

void CanvasPath::clone(Dart_Handle path_handle) {
  fml::RefPtr<CanvasPath> path = Create(path_handle);
  // per Skia docs, this will create a fast copy
  // data is shared until the source path or dest path are mutated
  path->sk_path_ = this->sk_path_;
}

const DlPath& CanvasPath::path() const {
  if (!dl_path_.has_value()) {
    dl_path_.emplace(sk_path_.snapshot());
  }
  return dl_path_.value();
}

}  // namespace flutter
