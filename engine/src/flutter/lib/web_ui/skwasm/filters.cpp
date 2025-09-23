// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"

#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/effects/dl_mask_filter.h"

using namespace Skwasm;
using namespace flutter;

SKWASM_EXPORT sp_wrapper<DlImageFilter>*
imageFilter_createBlur(DlScalar sigmaX, DlScalar sigmaY, DlTileMode tileMode) {
  liveImageFilterCount++;
  return new sp_wrapper<DlImageFilter>(
      DlImageFilter::MakeBlur(sigmaX, sigmaY, tileMode));
}

SKWASM_EXPORT sp_wrapper<DlImageFilter>* imageFilter_createDilate(
    DlScalar radiusX,
    DlScalar radiusY) {
  liveImageFilterCount++;
  return new sp_wrapper<DlImageFilter>(
      DlImageFilter::MakeDilate(radiusX, radiusY));
}

SKWASM_EXPORT sp_wrapper<DlImageFilter>* imageFilter_createErode(
    DlScalar radiusX,
    DlScalar radiusY) {
  liveImageFilterCount++;
  return new sp_wrapper<DlImageFilter>(
      DlImageFilter::MakeErode(radiusX, radiusY));
}

SKWASM_EXPORT sp_wrapper<DlImageFilter>* imageFilter_createMatrix(
    DlScalar* matrix33,
    FilterQuality quality) {
  liveImageFilterCount++;
  return new sp_wrapper<DlImageFilter>(DlImageFilter::MakeMatrix(
      createDlMatrixFrom3x3(matrix33), samplingOptionsForQuality(quality)));
}

SKWASM_EXPORT sp_wrapper<DlImageFilter>* imageFilter_createFromColorFilter(
    sp_wrapper<DlColorFilter>* filter) {
  liveImageFilterCount++;
  return new sp_wrapper<DlImageFilter>(
      DlImageFilter::MakeColorFilter(filter->shared()));
}

SKWASM_EXPORT sp_wrapper<DlImageFilter>* imageFilter_compose(
    sp_wrapper<DlImageFilter>* outer,
    sp_wrapper<DlImageFilter>* inner) {
  liveImageFilterCount++;
  return new sp_wrapper<DlImageFilter>(
      DlImageFilter::MakeCompose(outer->shared(), inner->shared()));
}

SKWASM_EXPORT void imageFilter_dispose(sp_wrapper<DlImageFilter>* filter) {
  liveImageFilterCount--;
  delete filter;
}

SKWASM_EXPORT void imageFilter_getFilterBounds(
    sp_wrapper<DlImageFilter>* filter,
    DlIRect* inOutBounds) {
  auto dlFilter = filter->shared();
  if (dlFilter == nullptr) {
    // If there is no filter, the output bounds are the same as the input
    // bounds.
    return;
  }
  DlIRect inRect = *inOutBounds;
  dlFilter->map_device_bounds(inRect, DlMatrix(), *inOutBounds);
}

SKWASM_EXPORT sp_wrapper<const DlColorFilter>* colorFilter_createMode(
    uint32_t color,
    DlBlendMode mode) {
  liveColorFilterCount++;
  return new sp_wrapper<const DlColorFilter>(
      DlColorFilter::MakeBlend(DlColor(color), mode));
}

SKWASM_EXPORT sp_wrapper<const DlColorFilter>* colorFilter_createMatrix(
    float* matrixData  // 20 values
) {
  liveColorFilterCount++;
  return new sp_wrapper<const DlColorFilter>(
      DlColorFilter::MakeMatrix(matrixData));
}

SKWASM_EXPORT sp_wrapper<const DlColorFilter>*
colorFilter_createSRGBToLinearGamma() {
  liveColorFilterCount++;
  return new sp_wrapper<const DlColorFilter>(
      DlColorFilter::MakeSrgbToLinearGamma());
}

SKWASM_EXPORT sp_wrapper<const DlColorFilter>*
colorFilter_createLinearToSRGBGamma() {
  liveColorFilterCount++;
  return new sp_wrapper<const DlColorFilter>(
      DlColorFilter::MakeLinearToSrgbGamma());
}

SKWASM_EXPORT void colorFilter_dispose(
    sp_wrapper<const DlColorFilter>* filter) {
  liveColorFilterCount--;
  delete filter;
}

SKWASM_EXPORT sp_wrapper<DlMaskFilter>* maskFilter_createBlur(
    DlBlurStyle blurStyle,
    DlScalar sigma) {
  liveMaskFilterCount++;
  return new sp_wrapper<DlMaskFilter>(DlBlurMaskFilter::Make(blurStyle, sigma));
}

SKWASM_EXPORT void maskFilter_dispose(sp_wrapper<DlMaskFilter>* filter) {
  liveMaskFilterCount--;
  delete filter;
}
