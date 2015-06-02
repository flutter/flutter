// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/ColorFilter.h"

namespace blink {

// static
PassRefPtr<ColorFilter> ColorFilter::create(CanvasColor color,
                                            TransferMode transfer_mode) {
  return adoptRef(new ColorFilter(adoptRef(SkColorFilter::CreateModeFilter(
      color.sk_color, transfer_mode.sk_mode))));
}

ColorFilter::ColorFilter(PassRefPtr<SkColorFilter> filter)
    : filter_(filter) {
}

ColorFilter::~ColorFilter() {
}

} // namespace blink
