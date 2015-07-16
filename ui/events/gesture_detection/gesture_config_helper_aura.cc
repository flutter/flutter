// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/gesture_config_helper.h"

#include <cmath>

#include "base/command_line.h"
#include "ui/events/event_switches.h"
#include "ui/events/gestures/gesture_configuration.h"

namespace ui {
namespace {

GestureDetector::Config DefaultGestureDetectorConfig() {
  GestureDetector::Config config;

  config.longpress_timeout = base::TimeDelta::FromMilliseconds(
      GestureConfiguration::long_press_time_in_ms());
  config.showpress_timeout = base::TimeDelta::FromMilliseconds(
      GestureConfiguration::show_press_delay_in_ms());
  config.double_tap_timeout = base::TimeDelta::FromMilliseconds(
      GestureConfiguration::semi_long_press_time_in_ms());
  config.touch_slop =
      GestureConfiguration::max_touch_move_in_pixels_for_click();
  config.double_tap_slop =
      GestureConfiguration::max_distance_between_taps_for_double_tap();
  config.minimum_fling_velocity =
      GestureConfiguration::min_scroll_velocity();
  config.maximum_fling_velocity = GestureConfiguration::fling_velocity_cap();
  config.swipe_enabled = true;
  config.minimum_swipe_velocity = GestureConfiguration::min_swipe_speed();
  config.maximum_swipe_deviation_angle =
      GestureConfiguration::max_swipe_deviation_angle();
  config.two_finger_tap_enabled = true;
  config.two_finger_tap_max_separation =
      GestureConfiguration::max_distance_for_two_finger_tap_in_pixels();
  config.two_finger_tap_timeout = base::TimeDelta::FromMilliseconds(
      GestureConfiguration::max_touch_down_duration_for_click_in_ms());

  return config;
}

ScaleGestureDetector::Config DefaultScaleGestureDetectorConfig() {
  ScaleGestureDetector::Config config;
  config.span_slop =
      GestureConfiguration::max_touch_move_in_pixels_for_click() * 2;
  config.min_scaling_touch_major = GestureConfiguration::default_radius() * 2;
  config.min_scaling_span = GestureConfiguration::min_scaling_span_in_pixels();
  config.min_pinch_update_span_delta = 0;
  return config;
}

}  // namespace

GestureProvider::Config DefaultGestureProviderConfig() {
  GestureProvider::Config config;
  config.gesture_detector_config = DefaultGestureDetectorConfig();
  config.scale_gesture_detector_config = DefaultScaleGestureDetectorConfig();
  config.gesture_begin_end_types_enabled = true;
  // Half the size of the default touch length is a reasonable minimum.
  config.min_gesture_bounds_length = GestureConfiguration::default_radius();
  return config;
}

}  // namespace ui
