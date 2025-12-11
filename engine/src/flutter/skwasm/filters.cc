// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/effects/dl_mask_filter.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlImageFilter>*
imageFilter_createBlur(flutter::DlScalar sigmaX,
                       flutter::DlScalar sigmaY,
                       flutter::DlTileMode tileMode) {
  Skwasm::live_image_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlImageFilter>(
      flutter::DlImageFilter::MakeBlur(sigmaX, sigmaY, tileMode));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlImageFilter>*
imageFilter_createDilate(flutter::DlScalar radiusX, flutter::DlScalar radiusY) {
  Skwasm::live_image_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlImageFilter>(
      flutter::DlImageFilter::MakeDilate(radiusX, radiusY));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlImageFilter>*
imageFilter_createErode(flutter::DlScalar radiusX, flutter::DlScalar radiusY) {
  Skwasm::live_image_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlImageFilter>(
      flutter::DlImageFilter::MakeErode(radiusX, radiusY));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlImageFilter>*
imageFilter_createMatrix(flutter::DlScalar* matrix33,
                         Skwasm::FilterQuality quality) {
  Skwasm::live_image_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlImageFilter>(
      flutter::DlImageFilter::MakeMatrix(
          Skwasm::createDlMatrixFrom3x3(matrix33),
          Skwasm::samplingOptionsForQuality(quality)));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlImageFilter>*
imageFilter_createFromColorFilter(
    Skwasm::sp_wrapper<flutter::DlColorFilter>* filter) {
  Skwasm::live_image_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlImageFilter>(
      flutter::DlImageFilter::MakeColorFilter(filter->Shared()));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlImageFilter>* imageFilter_compose(
    Skwasm::sp_wrapper<flutter::DlImageFilter>* outer,
    Skwasm::sp_wrapper<flutter::DlImageFilter>* inner) {
  Skwasm::live_image_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlImageFilter>(
      flutter::DlImageFilter::MakeCompose(outer->Shared(), inner->Shared()));
}

SKWASM_EXPORT void imageFilter_dispose(
    Skwasm::sp_wrapper<flutter::DlImageFilter>* filter) {
  Skwasm::live_image_filter_count--;
  delete filter;
}

SKWASM_EXPORT void imageFilter_getFilterBounds(
    Skwasm::sp_wrapper<flutter::DlImageFilter>* filter,
    flutter::DlIRect* inOutBounds) {
  auto dlFilter = filter->Shared();
  if (dlFilter == nullptr) {
    // If there is no filter, the output bounds are the same as the input
    // bounds.
    return;
  }
  flutter::DlIRect inRect = *inOutBounds;
  dlFilter->map_device_bounds(inRect, flutter::DlMatrix(), *inOutBounds);
}

SKWASM_EXPORT Skwasm::sp_wrapper<const flutter::DlColorFilter>*
colorFilter_createMode(uint32_t color, flutter::DlBlendMode mode) {
  Skwasm::live_color_filter_count++;
  return new Skwasm::sp_wrapper<const flutter::DlColorFilter>(
      flutter::DlColorFilter::MakeBlend(flutter::DlColor(color), mode));
}

SKWASM_EXPORT Skwasm::sp_wrapper<const flutter::DlColorFilter>*
colorFilter_createMatrix(float* matrixData  // 20 values
) {
  Skwasm::live_color_filter_count++;
  return new Skwasm::sp_wrapper<const flutter::DlColorFilter>(
      flutter::DlColorFilter::MakeMatrix(matrixData));
}

SKWASM_EXPORT Skwasm::sp_wrapper<const flutter::DlColorFilter>*
colorFilter_createSRGBToLinearGamma() {
  Skwasm::live_color_filter_count++;
  return new Skwasm::sp_wrapper<const flutter::DlColorFilter>(
      flutter::DlColorFilter::MakeSrgbToLinearGamma());
}

SKWASM_EXPORT Skwasm::sp_wrapper<const flutter::DlColorFilter>*
colorFilter_createLinearToSRGBGamma() {
  Skwasm::live_color_filter_count++;
  return new Skwasm::sp_wrapper<const flutter::DlColorFilter>(
      flutter::DlColorFilter::MakeLinearToSrgbGamma());
}

SKWASM_EXPORT void colorFilter_dispose(
    Skwasm::sp_wrapper<const flutter::DlColorFilter>* filter) {
  Skwasm::live_color_filter_count--;
  delete filter;
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlMaskFilter>* maskFilter_createBlur(
    flutter::DlBlurStyle blurStyle,
    flutter::DlScalar sigma) {
  Skwasm::live_mask_filter_count++;
  return new Skwasm::sp_wrapper<flutter::DlMaskFilter>(
      flutter::DlBlurMaskFilter::Make(blurStyle, sigma));
}

SKWASM_EXPORT void maskFilter_dispose(
    Skwasm::sp_wrapper<flutter::DlMaskFilter>* filter) {
  Skwasm::live_mask_filter_count--;
  delete filter;
}
