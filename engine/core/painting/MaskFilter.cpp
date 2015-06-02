// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/MaskFilter.h"

#include "third_party/skia/include/effects/SkBlurMaskFilter.h"

namespace blink {

// static
PassRefPtr<MaskFilter> MaskFilter::create(
      unsigned style, double sigma, unsigned flags) {
  return adoptRef(new MaskFilter(adoptRef(SkBlurMaskFilter::Create(
      static_cast<SkBlurStyle>(style), sigma, flags))));
}

MaskFilter::MaskFilter(PassRefPtr<SkMaskFilter> filter)
    : filter_(filter) {
}

MaskFilter::~MaskFilter() {
}

} // namespace blink
