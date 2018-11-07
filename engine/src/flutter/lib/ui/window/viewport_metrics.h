// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_VIEWPORT_METRICS_H_
#define FLUTTER_LIB_UI_WINDOW_VIEWPORT_METRICS_H_

#include <stdint.h>

namespace blink {

struct ViewportMetrics {
  double device_pixel_ratio = 1.0;
  double physical_width = 0;
  double physical_height = 0;
  double physical_padding_top = 0;
  double physical_padding_right = 0;
  double physical_padding_bottom = 0;
  double physical_padding_left = 0;
  double physical_view_inset_top = 0;
  double physical_view_inset_right = 0;
  double physical_view_inset_bottom = 0;
  double physical_view_inset_left = 0;
};

struct LogicalSize {
  double width = 0.0;
  double height = 0.0;
};

struct LogicalInset {
  double left = 0.0;
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
};

struct LogicalMetrics {
  LogicalSize size;
  double scale = 1.0;
  LogicalInset padding;
  LogicalInset view_inset;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_WINDOW_VIEWPORT_METRICS_H_
