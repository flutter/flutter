// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURES_GESTURE_CONFIGURATION_H_
#define UI_EVENTS_GESTURES_GESTURE_CONFIGURATION_H_

#include "base/basictypes.h"
#include "ui/events/events_base_export.h"

namespace ui {

// TODO: Expand this design to support multiple OS configuration
// approaches (windows, chrome, others).  This would turn into an
// abstract base class.

class EVENTS_BASE_EXPORT GestureConfiguration {
 public:
  // Ordered alphabetically ignoring underscores, to align with the
  // associated list of prefs in gesture_prefs_aura.cc.
  static float default_radius() {
    return default_radius_;
  }
  static void set_default_radius(float radius) {
    default_radius_ = radius;
  }
  static int fling_max_cancel_to_down_time_in_ms() {
    return fling_max_cancel_to_down_time_in_ms_;
  }
  static void set_fling_max_cancel_to_down_time_in_ms(int val) {
    fling_max_cancel_to_down_time_in_ms_ = val;
  }
  static int fling_max_tap_gap_time_in_ms() {
    return fling_max_tap_gap_time_in_ms_;
  }
  static void set_fling_max_tap_gap_time_in_ms(int val) {
    fling_max_tap_gap_time_in_ms_ = val;
  }
  static int long_press_time_in_ms() {
    return long_press_time_in_ms_;
  }
  static int semi_long_press_time_in_ms() {
    return semi_long_press_time_in_ms_;
  }
  static float max_distance_for_two_finger_tap_in_pixels() {
    return max_distance_for_two_finger_tap_in_pixels_;
  }
  static void set_max_distance_for_two_finger_tap_in_pixels(float val) {
    max_distance_for_two_finger_tap_in_pixels_ = val;
  }
  static void set_long_press_time_in_ms(int val) {
    long_press_time_in_ms_ = val;
  }
  static void set_semi_long_press_time_in_ms(int val) {
    semi_long_press_time_in_ms_ = val;
  }
  static int max_time_between_double_click_in_ms() {
    return max_time_between_double_click_in_ms_;
  }
  static void set_max_time_between_double_click_in_ms(int val) {
    max_time_between_double_click_in_ms_ = val;
  }
  static float max_separation_for_gesture_touches_in_pixels() {
    return max_separation_for_gesture_touches_in_pixels_;
  }
  static void set_max_separation_for_gesture_touches_in_pixels(float val) {
    max_separation_for_gesture_touches_in_pixels_ = val;
  }
  static float max_swipe_deviation_angle() {
    return max_swipe_deviation_angle_;
  }
  static void set_max_swipe_deviation_angle(float val) {
    max_swipe_deviation_angle_ = val;
  }
  static int max_touch_down_duration_for_click_in_ms() {
    return max_touch_down_duration_for_click_in_ms_;
  }
  static void set_max_touch_down_duration_for_click_in_ms(int val) {
    max_touch_down_duration_for_click_in_ms_ = val;
  }
  static float max_touch_move_in_pixels_for_click() {
    return max_touch_move_in_pixels_for_click_;
  }
  static void set_max_touch_move_in_pixels_for_click(float val) {
    max_touch_move_in_pixels_for_click_ = val;
  }
  static float max_distance_between_taps_for_double_tap() {
    return max_distance_between_taps_for_double_tap_;
  }
  static void set_max_distance_between_taps_for_double_tap(float val) {
    max_distance_between_taps_for_double_tap_ = val;
  }
  static float min_distance_for_pinch_scroll_in_pixels() {
    return min_distance_for_pinch_scroll_in_pixels_;
  }
  static void set_min_distance_for_pinch_scroll_in_pixels(float val) {
    min_distance_for_pinch_scroll_in_pixels_ = val;
  }
  static float min_pinch_update_distance_in_pixels() {
    return min_pinch_update_distance_in_pixels_;
  }
  static void set_min_pinch_update_distance_in_pixels(float val) {
    min_pinch_update_distance_in_pixels_ = val;
  }
  static float min_scroll_velocity() {
    return min_scroll_velocity_;
  }
  static void set_min_scroll_velocity(float val) {
    min_scroll_velocity_ = val;
  }
  static float min_swipe_speed() {
    return min_swipe_speed_;
  }
  static void set_min_swipe_speed(float val) {
    min_swipe_speed_ = val;
  }
  static float min_scaling_span_in_pixels() {
    return min_scaling_span_in_pixels_;
  };
  static void set_min_scaling_span_in_pixels(float val) {
    min_scaling_span_in_pixels_ = val;
  }
  static int show_press_delay_in_ms() {
    return show_press_delay_in_ms_;
  }
  static int set_show_press_delay_in_ms(int val) {
    return show_press_delay_in_ms_ = val;
  }
  static int scroll_debounce_interval_in_ms() {
    return scroll_debounce_interval_in_ms_;
  }
  static int set_scroll_debounce_interval_in_ms(int val) {
    return scroll_debounce_interval_in_ms_ = val;
  }
  static float fling_velocity_cap() {
    return fling_velocity_cap_;
  }
  static void set_fling_velocity_cap(float val) {
    fling_velocity_cap_ = val;
  }
  // TODO(davemoore): Move into chrome/browser/ui.
  static int tab_scrub_activation_delay_in_ms() {
    return tab_scrub_activation_delay_in_ms_;
  }
  static void set_tab_scrub_activation_delay_in_ms(int val) {
    tab_scrub_activation_delay_in_ms_ = val;
  }

 private:
  // These are listed in alphabetical order ignoring underscores, to
  // align with the associated list of preferences in
  // gesture_prefs_aura.cc. These two lists should be kept in sync.

  // The default touch radius length used when the only information given
  // by the device is the touch center.
  static float default_radius_;

  // The maximum allowed distance between two fingers for a two finger tap. If
  // the distance between two fingers is greater than this value, we will not
  // recognize a two finger tap.
  static float max_distance_for_two_finger_tap_in_pixels_;

  // Maximum time between a GestureFlingCancel and a mousedown such that the
  // mousedown is considered associated with the cancel event.
  static int fling_max_cancel_to_down_time_in_ms_;

  // Maxium time between a mousedown/mouseup pair that is considered to be a
  // suppressable tap.
  static int fling_max_tap_gap_time_in_ms_;

  static int long_press_time_in_ms_;
  static int semi_long_press_time_in_ms_;
  static int max_time_between_double_click_in_ms_;
  static float max_separation_for_gesture_touches_in_pixels_;
  static float max_swipe_deviation_angle_;
  static int max_touch_down_duration_for_click_in_ms_;
  static float max_touch_move_in_pixels_for_click_;
  static float max_distance_between_taps_for_double_tap_;
  static float min_distance_for_pinch_scroll_in_pixels_;
  // Only used with --compensate-for-unstable-pinch-zoom.
  static float min_pinch_update_distance_in_pixels_;
  static float min_scroll_velocity_;
  static float min_swipe_speed_;
  static float min_scaling_span_in_pixels_;
  static int show_press_delay_in_ms_;
  static int scroll_debounce_interval_in_ms_;
  static float fling_velocity_cap_;
  // TODO(davemoore): Move into chrome/browser/ui.
  static int tab_scrub_activation_delay_in_ms_;

  DISALLOW_COPY_AND_ASSIGN(GestureConfiguration);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURES_GESTURE_CONFIGURATION_H_
