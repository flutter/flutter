// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_color_filter.h"

#include "flutter/display_list/display_list_color.h"

namespace flutter {

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
