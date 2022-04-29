// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_color_filter.h"

#include "flutter/display_list/display_list_color.h"

namespace flutter {

std::shared_ptr<DlColorFilter> DlColorFilter::From(SkColorFilter* sk_filter) {
  if (sk_filter == nullptr) {
    return nullptr;
  }
  if (sk_filter == DlSrgbToLinearGammaColorFilter::sk_filter_.get()) {
    // Skia implements these filters as a singleton.
    return DlSrgbToLinearGammaColorFilter::instance;
  }
  if (sk_filter == DlLinearToSrgbGammaColorFilter::sk_filter_.get()) {
    // Skia implements these filters as a singleton.
    return DlLinearToSrgbGammaColorFilter::instance;
  }
  {
    SkColor color;
    SkBlendMode mode;
    if (sk_filter->asAColorMode(&color, &mode)) {
      return std::make_shared<DlBlendColorFilter>(color, ToDl(mode));
    }
  }
  {
    float matrix[20];
    if (sk_filter->asAColorMatrix(matrix)) {
      return std::make_shared<DlMatrixColorFilter>(matrix);
    }
  }
  return std::make_shared<DlUnknownColorFilter>(sk_ref_sp(sk_filter));
}

const std::shared_ptr<DlSrgbToLinearGammaColorFilter>
    DlSrgbToLinearGammaColorFilter::instance =
        std::make_shared<DlSrgbToLinearGammaColorFilter>();
const sk_sp<SkColorFilter> DlSrgbToLinearGammaColorFilter::sk_filter_ =
    SkColorFilters::SRGBToLinearGamma();

const std::shared_ptr<DlLinearToSrgbGammaColorFilter>
    DlLinearToSrgbGammaColorFilter::instance =
        std::make_shared<DlLinearToSrgbGammaColorFilter>();
const sk_sp<SkColorFilter> DlLinearToSrgbGammaColorFilter::sk_filter_ =
    SkColorFilters::LinearToSRGBGamma();

}  // namespace flutter
