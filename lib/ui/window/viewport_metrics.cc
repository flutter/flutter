// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/viewport_metrics.h"

namespace blink {
ViewportMetrics::ViewportMetrics() = default;

ViewportMetrics::ViewportMetrics(double p_device_pixel_ratio,
                                 double p_physical_width,
                                 double p_physical_height,
                                 double p_physical_padding_top,
                                 double p_physical_padding_right,
                                 double p_physical_padding_bottom,
                                 double p_physical_padding_left,
                                 double p_physical_view_inset_top,
                                 double p_physical_view_inset_right,
                                 double p_physical_view_inset_bottom,
                                 double p_physical_view_inset_left)
    : device_pixel_ratio(p_device_pixel_ratio),
      physical_width(p_physical_width),
      physical_height(p_physical_height),
      physical_padding_top(p_physical_padding_top),
      physical_padding_right(p_physical_padding_right),
      physical_padding_bottom(p_physical_padding_bottom),
      physical_padding_left(p_physical_padding_left),
      physical_view_inset_top(p_physical_view_inset_top),
      physical_view_inset_right(p_physical_view_inset_right),
      physical_view_inset_bottom(p_physical_view_inset_bottom),
      physical_view_inset_left(p_physical_view_inset_left) {}

ViewportMetrics::ViewportMetrics(const ViewportMetrics& other) = default;

}  // namespace blink
