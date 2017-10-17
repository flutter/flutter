// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PATH_H_
#define FLUTTER_LIB_UI_PAINTING_PATH_H_

#include "flutter/lib/ui/painting/rrect.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/float32_list.h"
#include "lib/tonic/typed_data/float64_list.h"
#include "third_party/skia/include/core/SkPath.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class CanvasPath : public fxl::RefCountedThreadSafe<CanvasPath>,
                   public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(CanvasPath);

 public:
  ~CanvasPath() override;
  static fxl::RefPtr<CanvasPath> Create() {
    return fxl::MakeRefCounted<CanvasPath>();
  }

  int getFillType();
  void setFillType(int fill_type);

  void moveTo(float x, float y);
  void relativeMoveTo(float x, float y);
  void lineTo(float x, float y);
  void relativeLineTo(float x, float y);
  void quadraticBezierTo(float x1, float y1, float x2, float y2);
  void relativeQuadraticBezierTo(float x1, float y1, float x2, float y2);
  void cubicTo(float x1, float y1, float x2, float y2, float x3, float y3);
  void relativeCubicTo(float x1,
                       float y1,
                       float x2,
                       float y2,
                       float x3,
                       float y3);
  void conicTo(float x1, float y1, float x2, float y2, float w);
  void relativeConicTo(float x1, float y1, float x2, float y2, float w);
  void arcTo(float left,
             float top,
             float right,
             float bottom,
             float startAngle,
             float sweepAngle,
             bool forceMoveTo);
  void arcToPoint(float arcEndX,
                  float arcEndY,
                  float radiusX,
                  float radiusY,
                  float xAxisRotation,
                  bool isLargeArc,
                  bool isClockwiseDirection);
  void relativeArcToPoint(float arcEndDeltaX,
                          float arcEndDeltaY,
                          float radiusX,
                          float radiusY,
                          float xAxisRotation,
                          bool isLargeArc,
                          bool isClockwiseDirection);
  void addRect(float left, float top, float right, float bottom);
  void addOval(float left, float top, float right, float bottom);
  void addArc(float left,
              float top,
              float right,
              float bottom,
              float startAngle,
              float sweepAngle);
  void addPolygon(const tonic::Float32List& points, bool close);
  void addRRect(const RRect& rrect);
  void addPath(CanvasPath* path, double dx, double dy);
  void extendWithPath(CanvasPath* path, double dx, double dy);
  void close();
  void reset();
  bool contains(double x, double y);
  fxl::RefPtr<CanvasPath> shift(double dx, double dy);
  fxl::RefPtr<CanvasPath> transform(tonic::Float64List& matrix4);

  const SkPath& path() const { return path_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  CanvasPath();

  SkPath path_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PATH_H_
