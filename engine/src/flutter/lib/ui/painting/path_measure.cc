// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/path_measure.h"

#define _USE_MATH_DEFINES
#include <math.h>

#include "flutter/lib/ui/painting/matrix.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace flutter {

typedef CanvasPathMeasure PathMeasure;

static void PathMeasure_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&CanvasPathMeasure::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, PathMeasure);

#define FOR_EACH_BINDING(V)  \
  V(PathMeasure, setPath)    \
  V(PathMeasure, getLength)  \
  V(PathMeasure, getPosTan)  \
  V(PathMeasure, getSegment) \
  V(PathMeasure, isClosed)   \
  V(PathMeasure, nextContour)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasPathMeasure::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"PathMeasure_constructor", PathMeasure_constructor, 3, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<CanvasPathMeasure> CanvasPathMeasure::Create(const CanvasPath* path,
                                                         bool forceClosed) {
  fml::RefPtr<CanvasPathMeasure> pathMeasure =
      fml::MakeRefCounted<CanvasPathMeasure>();
  if (path) {
    const SkPath skPath = path->path();
    SkScalar resScale = 1;
    pathMeasure->path_measure_ =
        std::make_unique<SkContourMeasureIter>(skPath, forceClosed, resScale);
  } else {
    pathMeasure->path_measure_ = std::make_unique<SkContourMeasureIter>();
  }
  return pathMeasure;
}

CanvasPathMeasure::CanvasPathMeasure() {}

CanvasPathMeasure::~CanvasPathMeasure() {}

void CanvasPathMeasure::setPath(const CanvasPath* path, bool isClosed) {
  const SkPath& skPath = path->path();
  path_measure_->reset(skPath, isClosed);
}

float CanvasPathMeasure::getLength(int contour_index) {
  if (static_cast<std::vector<sk_sp<SkContourMeasure>>::size_type>(
          contour_index) < measures_.size()) {
    return measures_[contour_index]->length();
  }
  return -1;
}

tonic::Float32List CanvasPathMeasure::getPosTan(int contour_index,
                                                float distance) {
  tonic::Float32List posTan(Dart_NewTypedData(Dart_TypedData_kFloat32, 5));
  posTan[0] = 0;  // dart code will check for this for failure
  if (static_cast<std::vector<sk_sp<SkContourMeasure>>::size_type>(
          contour_index) >= measures_.size()) {
    return posTan;
  }

  SkPoint pos;
  SkVector tan;
  bool success = measures_[contour_index]->getPosTan(distance, &pos, &tan);

  if (success) {
    posTan[0] = 1;  // dart code will check for this for success
    posTan[1] = pos.x();
    posTan[2] = pos.y();
    posTan[3] = tan.x();
    posTan[4] = tan.y();
  }

  return posTan;
}

void CanvasPathMeasure::getSegment(Dart_Handle path_handle,
                                   int contour_index,
                                   float start_d,
                                   float stop_d,
                                   bool start_with_move_to) {
  if (static_cast<std::vector<sk_sp<SkContourMeasure>>::size_type>(
          contour_index) >= measures_.size()) {
    CanvasPath::Create(path_handle);
  }
  SkPath dst;
  bool success = measures_[contour_index]->getSegment(start_d, stop_d, &dst,
                                                      start_with_move_to);
  if (!success) {
    CanvasPath::Create(path_handle);
  } else {
    CanvasPath::CreateFrom(path_handle, dst);
  }
}

bool CanvasPathMeasure::isClosed(int contour_index) {
  if (static_cast<std::vector<sk_sp<SkContourMeasure>>::size_type>(
          contour_index) < measures_.size()) {
    return measures_[contour_index]->isClosed();
  }
  return false;
}

bool CanvasPathMeasure::nextContour() {
  auto measure = path_measure_->next();
  if (measure) {
    measures_.push_back(std::move(measure));
    return true;
  }
  return false;
}

}  // namespace flutter
