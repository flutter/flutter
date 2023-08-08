// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/path.h"

#include <cmath>

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

CanvasPath::CanvasPath()
    : path_tracker_(UIDartState::Current()->GetVolatilePathTracker()),
      tracked_path_(std::make_shared<VolatilePathTracker::TrackedPath>()) {
  FML_DCHECK(path_tracker_);
  resetVolatility();
}

CanvasPath::~CanvasPath() = default;

void CanvasPath::resetVolatility() {
  if (!tracked_path_->tracking_volatility) {
    mutable_path().setIsVolatile(true);
    tracked_path_->frame_count = 0;
    tracked_path_->tracking_volatility = true;
    path_tracker_->Track(tracked_path_);
  }
}

int CanvasPath::getFillType() {
  return static_cast<int>(path().getFillType());
}

void CanvasPath::setFillType(int fill_type) {
  mutable_path().setFillType(static_cast<SkPathFillType>(fill_type));
  resetVolatility();
}

void CanvasPath::moveTo(double x, double y) {
  mutable_path().moveTo(SafeNarrow(x), SafeNarrow(y));
  resetVolatility();
}

void CanvasPath::relativeMoveTo(double x, double y) {
  mutable_path().rMoveTo(SafeNarrow(x), SafeNarrow(y));
  resetVolatility();
}

void CanvasPath::lineTo(double x, double y) {
  mutable_path().lineTo(SafeNarrow(x), SafeNarrow(y));
  resetVolatility();
}

void CanvasPath::relativeLineTo(double x, double y) {
  mutable_path().rLineTo(SafeNarrow(x), SafeNarrow(y));
  resetVolatility();
}

void CanvasPath::quadraticBezierTo(double x1, double y1, double x2, double y2) {
  mutable_path().quadTo(SafeNarrow(x1), SafeNarrow(y1), SafeNarrow(x2),
                        SafeNarrow(y2));
  resetVolatility();
}

void CanvasPath::relativeQuadraticBezierTo(double x1,
                                           double y1,
                                           double x2,
                                           double y2) {
  mutable_path().rQuadTo(SafeNarrow(x1), SafeNarrow(y1), SafeNarrow(x2),
                         SafeNarrow(y2));
  resetVolatility();
}

void CanvasPath::cubicTo(double x1,
                         double y1,
                         double x2,
                         double y2,
                         double x3,
                         double y3) {
  mutable_path().cubicTo(SafeNarrow(x1), SafeNarrow(y1), SafeNarrow(x2),
                         SafeNarrow(y2), SafeNarrow(x3), SafeNarrow(y3));
  resetVolatility();
}

void CanvasPath::relativeCubicTo(double x1,
                                 double y1,
                                 double x2,
                                 double y2,
                                 double x3,
                                 double y3) {
  mutable_path().rCubicTo(SafeNarrow(x1), SafeNarrow(y1), SafeNarrow(x2),
                          SafeNarrow(y2), SafeNarrow(x3), SafeNarrow(y3));
  resetVolatility();
}

void CanvasPath::conicTo(double x1, double y1, double x2, double y2, double w) {
  mutable_path().conicTo(SafeNarrow(x1), SafeNarrow(y1), SafeNarrow(x2),
                         SafeNarrow(y2), SafeNarrow(w));
  resetVolatility();
}

void CanvasPath::relativeConicTo(double x1,
                                 double y1,
                                 double x2,
                                 double y2,
                                 double w) {
  mutable_path().rConicTo(SafeNarrow(x1), SafeNarrow(y1), SafeNarrow(x2),
                          SafeNarrow(y2), SafeNarrow(w));
  resetVolatility();
}

void CanvasPath::arcTo(double left,
                       double top,
                       double right,
                       double bottom,
                       double startAngle,
                       double sweepAngle,
                       bool forceMoveTo) {
  mutable_path().arcTo(
      SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top), SafeNarrow(right),
                       SafeNarrow(bottom)),
      SafeNarrow(startAngle) * 180.0f / static_cast<float>(M_PI),
      SafeNarrow(sweepAngle) * 180.0f / static_cast<float>(M_PI), forceMoveTo);
  resetVolatility();
}

void CanvasPath::arcToPoint(double arcEndX,
                            double arcEndY,
                            double radiusX,
                            double radiusY,
                            double xAxisRotation,
                            bool isLargeArc,
                            bool isClockwiseDirection) {
  const auto arcSize = isLargeArc ? SkPath::ArcSize::kLarge_ArcSize
                                  : SkPath::ArcSize::kSmall_ArcSize;
  const auto direction =
      isClockwiseDirection ? SkPathDirection::kCW : SkPathDirection::kCCW;

  mutable_path().arcTo(SafeNarrow(radiusX), SafeNarrow(radiusY),
                       SafeNarrow(xAxisRotation), arcSize, direction,
                       SafeNarrow(arcEndX), SafeNarrow(arcEndY));
  resetVolatility();
}

void CanvasPath::relativeArcToPoint(double arcEndDeltaX,
                                    double arcEndDeltaY,
                                    double radiusX,
                                    double radiusY,
                                    double xAxisRotation,
                                    bool isLargeArc,
                                    bool isClockwiseDirection) {
  const auto arcSize = isLargeArc ? SkPath::ArcSize::kLarge_ArcSize
                                  : SkPath::ArcSize::kSmall_ArcSize;
  const auto direction =
      isClockwiseDirection ? SkPathDirection::kCW : SkPathDirection::kCCW;
  mutable_path().rArcTo(SafeNarrow(radiusX), SafeNarrow(radiusY),
                        SafeNarrow(xAxisRotation), arcSize, direction,
                        SafeNarrow(arcEndDeltaX), SafeNarrow(arcEndDeltaY));
  resetVolatility();
}

void CanvasPath::addRect(double left, double top, double right, double bottom) {
  mutable_path().addRect(SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                                          SafeNarrow(right),
                                          SafeNarrow(bottom)));
  resetVolatility();
}

void CanvasPath::addOval(double left, double top, double right, double bottom) {
  mutable_path().addOval(SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top),
                                          SafeNarrow(right),
                                          SafeNarrow(bottom)));
  resetVolatility();
}

void CanvasPath::addArc(double left,
                        double top,
                        double right,
                        double bottom,
                        double startAngle,
                        double sweepAngle) {
  mutable_path().addArc(
      SkRect::MakeLTRB(SafeNarrow(left), SafeNarrow(top), SafeNarrow(right),
                       SafeNarrow(bottom)),
      SafeNarrow(startAngle) * 180.0f / static_cast<float>(M_PI),
      SafeNarrow(sweepAngle) * 180.0f / static_cast<float>(M_PI));
  resetVolatility();
}

void CanvasPath::addPolygon(const tonic::Float32List& points, bool close) {
  mutable_path().addPoly(reinterpret_cast<const SkPoint*>(points.data()),
                         points.num_elements() / 2, close);
  resetVolatility();
}

void CanvasPath::addRRect(const RRect& rrect) {
  mutable_path().addRRect(rrect.sk_rrect);
  resetVolatility();
}

void CanvasPath::addPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(ToDart("Path.addPath called with non-genuine Path."));
    return;
  }
  mutable_path().addPath(path->path(), SafeNarrow(dx), SafeNarrow(dy),
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
  mutable_path().addPath(path->path(), matrix, SkPath::kAppend_AddPathMode);
  resetVolatility();
}

void CanvasPath::extendWithPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Path.extendWithPath called with non-genuine Path."));
    return;
  }
  mutable_path().addPath(path->path(), SafeNarrow(dx), SafeNarrow(dy),
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
  mutable_path().addPath(path->path(), matrix, SkPath::kExtend_AddPathMode);
  resetVolatility();
}

void CanvasPath::close() {
  mutable_path().close();
  resetVolatility();
}

void CanvasPath::reset() {
  mutable_path().reset();
  resetVolatility();
}

bool CanvasPath::contains(double x, double y) {
  return path().contains(SafeNarrow(x), SafeNarrow(y));
}

void CanvasPath::shift(Dart_Handle path_handle, double dx, double dy) {
  fml::RefPtr<CanvasPath> path = Create(path_handle);
  auto& other_mutable_path = path->mutable_path();
  mutable_path().offset(SafeNarrow(dx), SafeNarrow(dy), &other_mutable_path);
  resetVolatility();
}

void CanvasPath::transform(Dart_Handle path_handle,
                           Dart_Handle matrix4_handle) {
  tonic::Float64List matrix4(matrix4_handle);
  auto sk_matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  fml::RefPtr<CanvasPath> path = Create(path_handle);
  auto& other_mutable_path = path->mutable_path();
  mutable_path().transform(sk_matrix, &other_mutable_path);
}

tonic::Float32List CanvasPath::getBounds() {
  tonic::Float32List rect(Dart_NewTypedData(Dart_TypedData_kFloat32, 4));
  const SkRect& bounds = path().getBounds();
  rect[0] = bounds.left();
  rect[1] = bounds.top();
  rect[2] = bounds.right();
  rect[3] = bounds.bottom();
  return rect;
}

bool CanvasPath::op(CanvasPath* path1, CanvasPath* path2, int operation) {
  bool result = Op(path1->path(), path2->path(),
                   static_cast<SkPathOp>(operation), &tracked_path_->path);
  resetVolatility();
  return result;
}

void CanvasPath::clone(Dart_Handle path_handle) {
  fml::RefPtr<CanvasPath> path = Create(path_handle);
  // per Skia docs, this will create a fast copy
  // data is shared until the source path or dest path are mutated
  path->mutable_path() = this->path();
}

}  // namespace flutter
