// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/path.h"

#include <math.h>

#include "flutter/lib/ui/painting/matrix.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace blink {

typedef CanvasPath Path;

static void Path_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&CanvasPath::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Path);

#define FOR_EACH_BINDING(V)          \
  V(Path, getFillType)               \
  V(Path, setFillType)               \
  V(Path, moveTo)                    \
  V(Path, relativeMoveTo)            \
  V(Path, lineTo)                    \
  V(Path, relativeLineTo)            \
  V(Path, quadraticBezierTo)         \
  V(Path, relativeQuadraticBezierTo) \
  V(Path, cubicTo)                   \
  V(Path, relativeCubicTo)           \
  V(Path, conicTo)                   \
  V(Path, relativeConicTo)           \
  V(Path, arcTo)                     \
  V(Path, addRect)                   \
  V(Path, addOval)                   \
  V(Path, addArc)                    \
  V(Path, addPolygon)                \
  V(Path, addRRect)                  \
  V(Path, addPath)                   \
  V(Path, extendWithPath)            \
  V(Path, close)                     \
  V(Path, reset)                     \
  V(Path, contains)                  \
  V(Path, shift)                     \
  V(Path, transform)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasPath::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Path_constructor", Path_constructor, 1, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

CanvasPath::CanvasPath() {}

CanvasPath::~CanvasPath() {}

int CanvasPath::getFillType() {
  return path_.getFillType();
}

void CanvasPath::setFillType(int fill_type) {
  path_.setFillType(static_cast<SkPath::FillType>(fill_type));
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
  if (!path)
    Dart_ThrowException(ToDart("Path.addPath called with non-genuine Path."));
  path_.addPath(path->path(), dx, dy, SkPath::kAppend_AddPathMode);
}

void CanvasPath::extendWithPath(CanvasPath* path, double dx, double dy) {
  if (!path)
    Dart_ThrowException(ToDart("Path.extendWithPath called with non-genuine Path."));
  path_.addPath(path->path(), dx, dy, SkPath::kExtend_AddPathMode);
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

fxl::RefPtr<CanvasPath> CanvasPath::shift(double dx, double dy) {
  fxl::RefPtr<CanvasPath> path = CanvasPath::Create();
  path_.offset(dx, dy, &path->path_);
  return path;
}

fxl::RefPtr<CanvasPath> CanvasPath::transform(
    tonic::Float64List& matrix4) {
  fxl::RefPtr<CanvasPath> path = CanvasPath::Create();
  path_.transform(ToSkMatrix(matrix4), &path->path_);
  matrix4.Release();
  return path;
}

}  // namespace blink
