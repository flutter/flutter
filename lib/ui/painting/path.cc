// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/path.h"

#include <cmath>

#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace flutter {

typedef CanvasPath Path;

static void Path_constructor(Dart_NativeArguments args) {
  UIDartState::ThrowIfUIOperationsProhibited();
  DartCallConstructor(&CanvasPath::CreateNew, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Path);

#define FOR_EACH_BINDING(V)          \
  V(Path, addArc)                    \
  V(Path, addOval)                   \
  V(Path, addPath)                   \
  V(Path, addPolygon)                \
  V(Path, addRect)                   \
  V(Path, addRRect)                  \
  V(Path, arcTo)                     \
  V(Path, arcToPoint)                \
  V(Path, close)                     \
  V(Path, conicTo)                   \
  V(Path, contains)                  \
  V(Path, cubicTo)                   \
  V(Path, extendWithPath)            \
  V(Path, extendWithPathAndMatrix)   \
  V(Path, getFillType)               \
  V(Path, lineTo)                    \
  V(Path, moveTo)                    \
  V(Path, quadraticBezierTo)         \
  V(Path, relativeArcToPoint)        \
  V(Path, relativeConicTo)           \
  V(Path, relativeCubicTo)           \
  V(Path, relativeLineTo)            \
  V(Path, relativeMoveTo)            \
  V(Path, relativeQuadraticBezierTo) \
  V(Path, reset)                     \
  V(Path, setFillType)               \
  V(Path, shift)                     \
  V(Path, transform)                 \
  V(Path, getBounds)                 \
  V(Path, addPathWithMatrix)         \
  V(Path, op)                        \
  V(Path, clone)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasPath::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Path_constructor", Path_constructor, 1, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

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

void CanvasPath::moveTo(float x, float y) {
  mutable_path().moveTo(x, y);
  resetVolatility();
}

void CanvasPath::relativeMoveTo(float x, float y) {
  mutable_path().rMoveTo(x, y);
  resetVolatility();
}

void CanvasPath::lineTo(float x, float y) {
  mutable_path().lineTo(x, y);
  resetVolatility();
}

void CanvasPath::relativeLineTo(float x, float y) {
  mutable_path().rLineTo(x, y);
  resetVolatility();
}

void CanvasPath::quadraticBezierTo(float x1, float y1, float x2, float y2) {
  mutable_path().quadTo(x1, y1, x2, y2);
  resetVolatility();
}

void CanvasPath::relativeQuadraticBezierTo(float x1,
                                           float y1,
                                           float x2,
                                           float y2) {
  mutable_path().rQuadTo(x1, y1, x2, y2);
  resetVolatility();
}

void CanvasPath::cubicTo(float x1,
                         float y1,
                         float x2,
                         float y2,
                         float x3,
                         float y3) {
  mutable_path().cubicTo(x1, y1, x2, y2, x3, y3);
  resetVolatility();
}

void CanvasPath::relativeCubicTo(float x1,
                                 float y1,
                                 float x2,
                                 float y2,
                                 float x3,
                                 float y3) {
  mutable_path().rCubicTo(x1, y1, x2, y2, x3, y3);
  resetVolatility();
}

void CanvasPath::conicTo(float x1, float y1, float x2, float y2, float w) {
  mutable_path().conicTo(x1, y1, x2, y2, w);
  resetVolatility();
}

void CanvasPath::relativeConicTo(float x1,
                                 float y1,
                                 float x2,
                                 float y2,
                                 float w) {
  mutable_path().rConicTo(x1, y1, x2, y2, w);
  resetVolatility();
}

void CanvasPath::arcTo(float left,
                       float top,
                       float right,
                       float bottom,
                       float startAngle,
                       float sweepAngle,
                       bool forceMoveTo) {
  mutable_path().arcTo(SkRect::MakeLTRB(left, top, right, bottom),
                       startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI,
                       forceMoveTo);
  resetVolatility();
}

void CanvasPath::arcToPoint(float arcEndX,
                            float arcEndY,
                            float radiusX,
                            float radiusY,
                            float xAxisRotation,
                            bool isLargeArc,
                            bool isClockwiseDirection) {
  const auto arcSize = isLargeArc ? SkPath::ArcSize::kLarge_ArcSize
                                  : SkPath::ArcSize::kSmall_ArcSize;
  const auto direction =
      isClockwiseDirection ? SkPathDirection::kCW : SkPathDirection::kCCW;

  mutable_path().arcTo(radiusX, radiusY, xAxisRotation, arcSize, direction,
                       arcEndX, arcEndY);
  resetVolatility();
}

void CanvasPath::relativeArcToPoint(float arcEndDeltaX,
                                    float arcEndDeltaY,
                                    float radiusX,
                                    float radiusY,
                                    float xAxisRotation,
                                    bool isLargeArc,
                                    bool isClockwiseDirection) {
  const auto arcSize = isLargeArc ? SkPath::ArcSize::kLarge_ArcSize
                                  : SkPath::ArcSize::kSmall_ArcSize;
  const auto direction =
      isClockwiseDirection ? SkPathDirection::kCW : SkPathDirection::kCCW;
  mutable_path().rArcTo(radiusX, radiusY, xAxisRotation, arcSize, direction,
                        arcEndDeltaX, arcEndDeltaY);
  resetVolatility();
}

void CanvasPath::addRect(float left, float top, float right, float bottom) {
  mutable_path().addRect(SkRect::MakeLTRB(left, top, right, bottom));
  resetVolatility();
}

void CanvasPath::addOval(float left, float top, float right, float bottom) {
  mutable_path().addOval(SkRect::MakeLTRB(left, top, right, bottom));
  resetVolatility();
}

void CanvasPath::addArc(float left,
                        float top,
                        float right,
                        float bottom,
                        float startAngle,
                        float sweepAngle) {
  mutable_path().addArc(SkRect::MakeLTRB(left, top, right, bottom),
                        startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI);
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
  mutable_path().addPath(path->path(), dx, dy, SkPath::kAppend_AddPathMode);
  resetVolatility();
}

void CanvasPath::addPathWithMatrix(CanvasPath* path,
                                   double dx,
                                   double dy,
                                   tonic::Float64List& matrix4) {
  if (!path) {
    matrix4.Release();
    Dart_ThrowException(
        ToDart("Path.addPathWithMatrix called with non-genuine Path."));
    return;
  }

  SkMatrix matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  matrix.setTranslateX(matrix.getTranslateX() + dx);
  matrix.setTranslateY(matrix.getTranslateY() + dy);
  mutable_path().addPath(path->path(), matrix, SkPath::kAppend_AddPathMode);
  resetVolatility();
}

void CanvasPath::extendWithPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Path.extendWithPath called with non-genuine Path."));
    return;
  }
  mutable_path().addPath(path->path(), dx, dy, SkPath::kExtend_AddPathMode);
  resetVolatility();
}

void CanvasPath::extendWithPathAndMatrix(CanvasPath* path,
                                         double dx,
                                         double dy,
                                         tonic::Float64List& matrix4) {
  if (!path) {
    matrix4.Release();
    Dart_ThrowException(
        ToDart("Path.addPathWithMatrix called with non-genuine Path."));
    return;
  }

  SkMatrix matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  matrix.setTranslateX(matrix.getTranslateX() + dx);
  matrix.setTranslateY(matrix.getTranslateY() + dy);
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
  return path().contains(x, y);
}

void CanvasPath::shift(Dart_Handle path_handle, double dx, double dy) {
  fml::RefPtr<CanvasPath> path = CanvasPath::Create(path_handle);
  auto& other_mutable_path = path->mutable_path();
  mutable_path().offset(dx, dy, &other_mutable_path);
  resetVolatility();
}

void CanvasPath::transform(Dart_Handle path_handle,
                           tonic::Float64List& matrix4) {
  auto sk_matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  fml::RefPtr<CanvasPath> path = CanvasPath::Create(path_handle);
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
  return Op(path1->path(), path2->path(), static_cast<SkPathOp>(operation),
            &tracked_path_->path);
  resetVolatility();
}

void CanvasPath::clone(Dart_Handle path_handle) {
  fml::RefPtr<CanvasPath> path = CanvasPath::Create(path_handle);
  // per Skia docs, this will create a fast copy
  // data is shared until the source path or dest path are mutated
  path->mutable_path() = this->path();
}

// This is doomed to be called too early, since Paths are mutable.
// However, it can help for some of the clone/shift/transform type methods
// where the resultant path will initially have a meaningful size.
size_t CanvasPath::GetAllocationSize() const {
  return sizeof(CanvasPath) + path().approximateBytesUsed();
}

}  // namespace flutter
