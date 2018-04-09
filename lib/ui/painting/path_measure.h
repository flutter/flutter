// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PATH_MEASURE_H_
#define FLUTTER_LIB_UI_PAINTING_PATH_MEASURE_H_

#include "flutter/lib/ui/painting/path.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/float64_list.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPathMeasure.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

// Be sure that the client doesn't modify a path on us before Skia finishes
// See AOSP's reasoning in PathMeasure.cpp

namespace blink {

class CanvasPathMeasure : public fxl::RefCountedThreadSafe<CanvasPathMeasure>,
                   public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(CanvasPathMeasure);

 public:
  ~CanvasPathMeasure() override;
  static fxl::RefPtr<CanvasPathMeasure> Create(const CanvasPath* path, bool forceClosed);

  void setPath(const CanvasPath* path, bool isClosed);
  float getLength();
  tonic::Float32List getPosTan(float distance);
  fxl::RefPtr<CanvasPath> getSegment(float startD, float stopD, bool startWithMoveTo);
  bool isClosed();
  bool nextContour();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  const SkPathMeasure& pathMeasure() const { return *path_measure_; }

 private:
  CanvasPathMeasure();

  std::unique_ptr<SkPathMeasure> path_measure_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PATH_MEASURE_H_
