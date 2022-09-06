// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PATH_H_
#define FLUTTER_LIB_UI_PAINTING_PATH_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/volatile_path_tracker.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/pathops/SkPathOps.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

class CanvasPath : public RefCountedDartWrappable<CanvasPath> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(CanvasPath);

 public:
  ~CanvasPath() override;

  static void CreateFrom(Dart_Handle path_handle, const SkPath& src) {
    auto path = fml::MakeRefCounted<CanvasPath>();
    path->AssociateWithDartWrapper(path_handle);
    path->tracked_path_->path = src;
  }

  static fml::RefPtr<CanvasPath> Create(Dart_Handle wrapper) {
    UIDartState::ThrowIfUIOperationsProhibited();
    auto res = fml::MakeRefCounted<CanvasPath>();
    res->AssociateWithDartWrapper(wrapper);
    return res;
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

  void addPathWithMatrix(CanvasPath* path,
                         double dx,
                         double dy,
                         Dart_Handle matrix4_handle);

  void extendWithPath(CanvasPath* path, double dx, double dy);

  void extendWithPathAndMatrix(CanvasPath* path,
                               double dx,
                               double dy,
                               Dart_Handle matrix4_handle);

  void close();
  void reset();
  bool contains(double x, double y);
  void shift(Dart_Handle path_handle, double dx, double dy);

  void transform(Dart_Handle path_handle, Dart_Handle matrix4_handle);

  tonic::Float32List getBounds();
  bool op(CanvasPath* path1, CanvasPath* path2, int operation);
  void clone(Dart_Handle path_handle);

  const SkPath& path() const { return tracked_path_->path; }

 private:
  CanvasPath();

  std::shared_ptr<VolatilePathTracker> path_tracker_;
  std::shared_ptr<VolatilePathTracker::TrackedPath> tracked_path_;

  // Must be called whenever the path is created or mutated.
  void resetVolatility();

  SkPath& mutable_path() { return tracked_path_->path; }
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PATH_H_
