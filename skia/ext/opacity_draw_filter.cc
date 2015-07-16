// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/opacity_draw_filter.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace skia {

OpacityDrawFilter::OpacityDrawFilter(float opacity,
                                     bool disable_image_filtering)
    : alpha_(SkScalarRoundToInt(opacity * 255)),
      disable_image_filtering_(disable_image_filtering) {}

OpacityDrawFilter::~OpacityDrawFilter() {}

bool OpacityDrawFilter::filter(SkPaint* paint, Type type) {
  if (alpha_ < 255)
    paint->setAlpha(alpha_);
  if (disable_image_filtering_)
    paint->setFilterQuality(kNone_SkFilterQuality);
  return true;
}

}  // namespace skia


