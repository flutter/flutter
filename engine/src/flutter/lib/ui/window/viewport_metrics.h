// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_VIEWPORT_METRICS_H_
#define FLUTTER_LIB_UI_WINDOW_VIEWPORT_METRICS_H_

#include <stdint.h>

namespace flutter {

// This is the value of double.maxFinite from dart:core.
// Platforms that do not explicitly set a depth will use this value, which
// avoids the need to special case logic that wants to check the max depth on
// the Dart side.
static const double kUnsetDepth = 1.7976931348623157e+308;

struct ViewportMetrics {
  ViewportMetrics() = default;
  ViewportMetrics(const ViewportMetrics& other) = default;

  // Create a 2D ViewportMetrics instance.
  ViewportMetrics(double p_device_pixel_ratio,
                  double p_physical_width,
                  double p_physical_height,
                  double p_physical_padding_top,
                  double p_physical_padding_right,
                  double p_physical_padding_bottom,
                  double p_physical_padding_left,
                  double p_physical_view_inset_top,
                  double p_physical_view_inset_right,
                  double p_physical_view_inset_bottom,
                  double p_physical_view_inset_left,
                  double p_physical_system_gesture_inset_top,
                  double p_physical_system_gesture_inset_right,
                  double p_physical_system_gesture_inset_bottom,
                  double p_physical_system_gesture_inset_left);

  // Create a ViewportMetrics instance that contains z information.
  ViewportMetrics(double p_device_pixel_ratio,
                  double p_physical_width,
                  double p_physical_height,
                  double p_physical_depth,
                  double p_physical_padding_top,
                  double p_physical_padding_right,
                  double p_physical_padding_bottom,
                  double p_physical_padding_left,
                  double p_physical_view_inset_front,
                  double p_physical_view_inset_back,
                  double p_physical_view_inset_top,
                  double p_physical_view_inset_right,
                  double p_physical_view_inset_bottom,
                  double p_physical_view_inset_left);

  // Create a ViewportMetrics instance that doesn't include depth, padding, or
  // insets.
  ViewportMetrics(double p_device_pixel_ratio,
                  double p_physical_width,
                  double p_physical_height);

  double device_pixel_ratio = 1.0;
  double physical_width = 0;
  double physical_height = 0;
  double physical_depth = kUnsetDepth;
  double physical_padding_top = 0;
  double physical_padding_right = 0;
  double physical_padding_bottom = 0;
  double physical_padding_left = 0;
  double physical_view_inset_top = 0;
  double physical_view_inset_right = 0;
  double physical_view_inset_bottom = 0;
  double physical_view_inset_left = 0;
  double physical_view_inset_front = kUnsetDepth;
  double physical_view_inset_back = kUnsetDepth;
  double physical_system_gesture_inset_top = 0;
  double physical_system_gesture_inset_right = 0;
  double physical_system_gesture_inset_bottom = 0;
  double physical_system_gesture_inset_left = 0;
};

struct LogicalSize {
  double width = 0.0;
  double height = 0.0;
  double depth = kUnsetDepth;
};

struct LogicalInset {
  double left = 0.0;
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
  double front = kUnsetDepth;
  double back = kUnsetDepth;
};

struct LogicalMetrics {
  LogicalSize size;
  double scale = 1.0;
  double scale_z = 1.0;
  LogicalInset padding;
  LogicalInset view_inset;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_WINDOW_VIEWPORT_METRICS_H_
