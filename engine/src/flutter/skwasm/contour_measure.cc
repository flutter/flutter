// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"
#include "third_party/skia/include/core/SkContourMeasure.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPathBuilder.h"

SKWASM_EXPORT SkContourMeasureIter* contourMeasureIter_create(
    SkPathBuilder* path,
    bool force_closed,
    SkScalar res_scale) {
  Skwasm::live_contour_measure_iter_count++;
  return new SkContourMeasureIter(path->snapshot(), force_closed, res_scale);
}

SKWASM_EXPORT SkContourMeasure* contourMeasureIter_next(
    SkContourMeasureIter* iter) {
  auto next = iter->next();
  if (next) {
    Skwasm::live_contour_measure_count++;
    next->ref();
  }
  return next.get();
}

SKWASM_EXPORT void contourMeasureIter_dispose(SkContourMeasureIter* iter) {
  Skwasm::live_contour_measure_iter_count--;
  delete iter;
}

SKWASM_EXPORT void contourMeasure_dispose(SkContourMeasure* measure) {
  Skwasm::live_contour_measure_count--;
  measure->unref();
}

SKWASM_EXPORT SkScalar contourMeasure_length(SkContourMeasure* measure) {
  return measure->length();
}

SKWASM_EXPORT bool contourMeasure_isClosed(SkContourMeasure* measure) {
  return measure->isClosed();
}

SKWASM_EXPORT bool contourMeasure_getPosTan(SkContourMeasure* measure,
                                            SkScalar distance,
                                            SkPoint* out_position,
                                            SkVector* out_tangent) {
  return measure->getPosTan(distance, out_position, out_tangent);
}

SKWASM_EXPORT SkPathBuilder* contourMeasure_getSegment(
    SkContourMeasure* measure,
    SkScalar start_d,
    SkScalar stop_d,
    bool start_with_move_to) {
  SkPathBuilder* out_path = new SkPathBuilder();
  if (!measure->getSegment(start_d, stop_d, out_path, start_with_move_to)) {
    delete out_path;
    return nullptr;
  }
  Skwasm::live_path_count++;
  return out_path;
}
