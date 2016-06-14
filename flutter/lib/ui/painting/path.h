// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PATH_H_
#define FLUTTER_LIB_UI_PAINTING_PATH_H_

#include "base/memory/ref_counted.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/float32_list.h"
#include "flutter/tonic/float64_list.h"
#include "third_party/skia/include/core/SkPath.h"

namespace blink {
class DartLibraryNatives;

class CanvasPath : public base::RefCountedThreadSafe<CanvasPath>,
                   public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~CanvasPath() override;
  static scoped_refptr<CanvasPath> Create() { return new CanvasPath(); }

  int getFillType();
  void setFillType(int fill_type);

  void moveTo(float x, float y);
  void relativeMoveTo(float x, float y);
  void lineTo(float x, float y);
  void relativeLineTo(float x, float y);
  void quadraticBezierTo(float x1, float y1, float x2, float y2);
  void relativeQuadraticBezierTo(float x1, float y1, float x2, float y2);
  void cubicTo(float x1, float y1, float x2, float y2, float x3, float y3);
  void relativeCubicTo(float x1, float y1, float x2, float y2, float x3, float y3);
  void conicTo(float x1, float y1, float x2, float y2, float w);
  void relativeConicTo(float x1, float y1, float x2, float y2, float w);
  void arcTo(float left, float top, float right, float bottom, float startAngle, float sweepAngle, bool forceMoveTo);
  void addRect(float left, float top, float right, float bottom);
  void addOval(float left, float top, float right, float bottom);
  void addArc(float left, float top, float right, float bottom, float startAngle, float sweepAngle);
  void addPolygon(const Float32List& points, bool close);
  void addRRect(const RRect& rrect);
  void addPath(CanvasPath* path, double dx, double dy);
  void extendWithPath(CanvasPath* path, double dx, double dy);
  void close();
  void reset();
  bool contains(double x, double y);
  scoped_refptr<CanvasPath> shift(double dx, double dy);
  scoped_refptr<CanvasPath> transform(const Float64List& matrix4);

  const SkPath& path() const { return path_; }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  CanvasPath();

  SkPath path_;
};

} // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PATH_H_
