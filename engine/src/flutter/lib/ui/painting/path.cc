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

CanvasPath::CanvasPath() {}

CanvasPath::~CanvasPath() {}

int CanvasPath::getFillType() {
  return static_cast<int>(path_.getFillType());
}

void CanvasPath::setFillType(int fill_type) {
  path_.setFillType(static_cast<SkPathFillType>(fill_type));
}

void CanvasPath::moveTo(float x, float y) {
  path_.moveTo(x, y);
}

void CanvasPath::relativeMoveTo(float x, float y) {
  path_.rMoveTo(x, y);
}

void CanvasPath::lineTo(float x, float y) {
  path_.lineTo(x, y);
}

void CanvasPath::relativeLineTo(float x, float y) {
  path_.rLineTo(x, y);
}

void CanvasPath::quadraticBezierTo(float x1, float y1, float x2, float y2) {
  path_.quadTo(x1, y1, x2, y2);
}

void CanvasPath::relativeQuadraticBezierTo(float x1,
                                           float y1,
                                           float x2,
                                           float y2) {
  path_.rQuadTo(x1, y1, x2, y2);
}

void CanvasPath::cubicTo(float x1,
                         float y1,
                         float x2,
                         float y2,
                         float x3,
                         float y3) {
  path_.cubicTo(x1, y1, x2, y2, x3, y3);
}

void CanvasPath::relativeCubicTo(float x1,
                                 float y1,
                                 float x2,
                                 float y2,
                                 float x3,
                                 float y3) {
  path_.rCubicTo(x1, y1, x2, y2, x3, y3);
}

void CanvasPath::conicTo(float x1, float y1, float x2, float y2, float w) {
  path_.conicTo(x1, y1, x2, y2, w);
}

void CanvasPath::relativeConicTo(float x1,
                                 float y1,
                                 float x2,
                                 float y2,
                                 float w) {
  path_.rConicTo(x1, y1, x2, y2, w);
}

void CanvasPath::arcTo(float left,
                       float top,
                       float right,
                       float bottom,
                       float startAngle,
                       float sweepAngle,
                       bool forceMoveTo) {
  path_.arcTo(SkRect::MakeLTRB(left, top, right, bottom),
              startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI,
              forceMoveTo);
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

  path_.arcTo(radiusX, radiusY, xAxisRotation, arcSize, direction, arcEndX,
              arcEndY);
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
  path_.rArcTo(radiusX, radiusY, xAxisRotation, arcSize, direction,
               arcEndDeltaX, arcEndDeltaY);
}

void CanvasPath::addRect(float left, float top, float right, float bottom) {
  path_.addRect(SkRect::MakeLTRB(left, top, right, bottom));
}

void CanvasPath::addOval(float left, float top, float right, float bottom) {
  path_.addOval(SkRect::MakeLTRB(left, top, right, bottom));
}

void CanvasPath::addArc(float left,
                        float top,
                        float right,
                        float bottom,
                        float startAngle,
                        float sweepAngle) {
  path_.addArc(SkRect::MakeLTRB(left, top, right, bottom),
               startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI);
}

void CanvasPath::addPolygon(const tonic::Float32List& points, bool close) {
  path_.addPoly(reinterpret_cast<const SkPoint*>(points.data()),
                points.num_elements() / 2, close);
}

void CanvasPath::addRRect(const RRect& rrect) {
  path_.addRRect(rrect.sk_rrect);
}

void CanvasPath::addPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(ToDart("Path.addPath called with non-genuine Path."));
    return;
  }
  path_.addPath(path->path(), dx, dy, SkPath::kAppend_AddPathMode);
}

void CanvasPath::addPathWithMatrix(CanvasPath* path,
                                   double dx,
                                   double dy,
                                   tonic::Float64List& matrix4) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Path.addPathWithMatrix called with non-genuine Path."));
    return;
  }

  SkMatrix matrix = ToSkMatrix(matrix4);
  matrix.setTranslateX(matrix.getTranslateX() + dx);
  matrix.setTranslateY(matrix.getTranslateY() + dy);
  path_.addPath(path->path(), matrix, SkPath::kAppend_AddPathMode);
  matrix4.Release();
}

void CanvasPath::extendWithPath(CanvasPath* path, double dx, double dy) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Path.extendWithPath called with non-genuine Path."));
    return;
  }
  path_.addPath(path->path(), dx, dy, SkPath::kExtend_AddPathMode);
}

void CanvasPath::extendWithPathAndMatrix(CanvasPath* path,
                                         double dx,
                                         double dy,
                                         tonic::Float64List& matrix4) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Path.addPathWithMatrix called with non-genuine Path."));
    return;
  }

  SkMatrix matrix = ToSkMatrix(matrix4);
  matrix.setTranslateX(matrix.getTranslateX() + dx);
  matrix.setTranslateY(matrix.getTranslateY() + dy);
  path_.addPath(path->path(), matrix, SkPath::kExtend_AddPathMode);
  matrix4.Release();
}

void CanvasPath::close() {
  path_.close();
}

void CanvasPath::reset() {
  path_.reset();
}

bool CanvasPath::contains(double x, double y) {
  return path_.contains(x, y);
}

void CanvasPath::shift(Dart_Handle path_handle, double dx, double dy) {
  fml::RefPtr<CanvasPath> path = CanvasPath::Create(path_handle);
  path_.offset(dx, dy, &path->path_);
}

void CanvasPath::transform(Dart_Handle path_handle,
                           tonic::Float64List& matrix4) {
  fml::RefPtr<CanvasPath> path = CanvasPath::Create(path_handle);
  path_.transform(ToSkMatrix(matrix4), &path->path_);
  matrix4.Release();
}

tonic::Float32List CanvasPath::getBounds() {
  tonic::Float32List rect(Dart_NewTypedData(Dart_TypedData_kFloat32, 4));
  const SkRect& bounds = path_.getBounds();
  rect[0] = bounds.left();
  rect[1] = bounds.top();
  rect[2] = bounds.right();
  rect[3] = bounds.bottom();
  return rect;
}

bool CanvasPath::op(CanvasPath* path1, CanvasPath* path2, int operation) {
  return Op(path1->path(), path2->path(), static_cast<SkPathOp>(operation),
            &path_);
}

void CanvasPath::clone(Dart_Handle path_handle) {
  fml::RefPtr<CanvasPath> path = CanvasPath::Create(path_handle);
  // per Skia docs, this will create a fast copy
  // data is shared until the source path or dest path are mutated
  path->path_ = path_;
}

// This is doomed to be called too early, since Paths are mutable.
// However, it can help for some of the clone/shift/transform type methods
// where the resultant path will initially have a meaningful size.
size_t CanvasPath::GetAllocationSize() const {
  return sizeof(CanvasPath) + path_.approximateBytesUsed();
}

}  // namespace flutter
