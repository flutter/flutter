// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_DISPLAY_METRICS_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_DISPLAY_METRICS_H_

#include "sky/engine/public/platform/WebSize.h"

namespace blink {

struct SkyDisplayMetrics {
  float device_pixel_ratio = 1.0;
  int physical_width = 0;
  int physical_height = 0;
  int physical_padding_top = 0;
  int physical_padding_right = 0;
  int physical_padding_bottom = 0;
  int physical_padding_left = 0;
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_DISPLAY_METRICS_H_
