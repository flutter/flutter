// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"

#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

using namespace Skwasm;

SKWASM_EXPORT SkImageFilter* imageFilter_createBlur(SkScalar sigmaX,
                                                    SkScalar sigmaY,
                                                    SkTileMode tileMode) {
  liveImageFilterCount++;
  return SkImageFilters::Blur(sigmaX, sigmaY, tileMode, nullptr).release();
}

SKWASM_EXPORT SkImageFilter* imageFilter_createDilate(SkScalar radiusX,
                                                      SkScalar radiusY) {
  liveImageFilterCount++;
  return SkImageFilters::Dilate(radiusX, radiusY, nullptr).release();
}

SKWASM_EXPORT SkImageFilter* imageFilter_createErode(SkScalar radiusX,
                                                     SkScalar radiusY) {
  liveImageFilterCount++;
  return SkImageFilters::Erode(radiusX, radiusY, nullptr).release();
}

SKWASM_EXPORT SkImageFilter* imageFilter_createMatrix(SkScalar* matrix33,
                                                      FilterQuality quality) {
  liveImageFilterCount++;
  return SkImageFilters::MatrixTransform(createMatrix(matrix33),
                                         samplingOptionsForQuality(quality),
                                         nullptr)
      .release();
}

SKWASM_EXPORT SkImageFilter* imageFilter_createFromColorFilter(
    SkColorFilter* filter) {
  liveImageFilterCount++;
  return SkImageFilters::ColorFilter(sk_ref_sp<SkColorFilter>(filter), nullptr)
      .release();
}

SKWASM_EXPORT SkImageFilter* imageFilter_compose(SkImageFilter* outer,
                                                 SkImageFilter* inner) {
  liveImageFilterCount++;

  return SkImageFilters::Compose(sk_ref_sp<SkImageFilter>(outer),
                                 sk_ref_sp<SkImageFilter>(inner))
      .release();
}

SKWASM_EXPORT void imageFilter_dispose(SkImageFilter* filter) {
  liveImageFilterCount--;
  filter->unref();
}

SKWASM_EXPORT void imageFilter_getFilterBounds(SkImageFilter* filter,
                                               SkIRect* inOutBounds) {
  SkIRect outputRect =
      filter->filterBounds(*inOutBounds, SkMatrix(),
                           SkImageFilter::MapDirection::kForward_MapDirection);
  *inOutBounds = outputRect;
}

SKWASM_EXPORT SkColorFilter* colorFilter_createMode(SkColor color,
                                                    SkBlendMode mode) {
  liveColorFilterCount++;
  return SkColorFilters::Blend(color, mode).release();
}

SKWASM_EXPORT SkColorFilter* colorFilter_createMatrix(
    float* matrixData  // 20 values
) {
  liveColorFilterCount++;
  return SkColorFilters::Matrix(matrixData).release();
}

SKWASM_EXPORT SkColorFilter* colorFilter_createSRGBToLinearGamma() {
  liveColorFilterCount++;
  return SkColorFilters::SRGBToLinearGamma().release();
}

SKWASM_EXPORT SkColorFilter* colorFilter_createLinearToSRGBGamma() {
  liveColorFilterCount++;
  return SkColorFilters::LinearToSRGBGamma().release();
}

SKWASM_EXPORT SkColorFilter* colorFilter_compose(SkColorFilter* outer,
                                                 SkColorFilter* inner) {
  liveColorFilterCount++;
  return SkColorFilters::Compose(sk_ref_sp<SkColorFilter>(outer),
                                 sk_ref_sp<SkColorFilter>(inner))
      .release();
}

SKWASM_EXPORT void colorFilter_dispose(SkColorFilter* filter) {
  liveColorFilterCount--;
  filter->unref();
}

SKWASM_EXPORT SkMaskFilter* maskFilter_createBlur(SkBlurStyle blurStyle,
                                                  SkScalar sigma) {
  liveMaskFilterCount++;
  return SkMaskFilter::MakeBlur(blurStyle, sigma).release();
}

SKWASM_EXPORT void maskFilter_dispose(SkMaskFilter* filter) {
  liveMaskFilterCount--;
  filter->unref();
}
