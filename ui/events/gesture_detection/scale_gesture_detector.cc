// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/scale_gesture_detector.h"

#include <limits.h>
#include <cmath>

#include "base/logging.h"
#include "ui/events/gesture_detection/motion_event.h"
#include "ui/events/gesture_detection/scale_gesture_listeners.h"

using base::TimeDelta;
using base::TimeTicks;

namespace ui {
namespace {

// Using a small epsilon when comparing slop distances allows pixel perfect
// slop determination when using fractional DPI coordinates (assuming the slop
// region and DPI scale are reasonably proportioned).
const float kSlopEpsilon = .05f;

const int kTouchStabilizeTimeMs = 128;

const float kScaleFactor = .5f;

}  // namespace

// Note: These constants were taken directly from the default (unscaled)
// versions found in Android's ViewConfiguration.
ScaleGestureDetector::Config::Config()
    : span_slop(16),
      min_scaling_touch_major(48),
      min_scaling_span(200),
      min_pinch_update_span_delta(0) {
}

ScaleGestureDetector::Config::~Config() {}

ScaleGestureDetector::ScaleGestureDetector(const Config& config,
                                           ScaleGestureListener* listener)
    : listener_(listener),
      focus_x_(0),
      focus_y_(0),
      curr_span_(0),
      prev_span_(0),
      initial_span_(0),
      curr_span_x_(0),
      curr_span_y_(0),
      prev_span_x_(0),
      prev_span_y_(0),
      in_progress_(0),
      span_slop_(0),
      min_span_(0),
      touch_upper_(0),
      touch_lower_(0),
      touch_history_last_accepted_(0),
      touch_history_direction_(0),
      touch_min_major_(0),
      touch_max_major_(0),
      double_tap_focus_x_(0),
      double_tap_focus_y_(0),
      double_tap_mode_(DOUBLE_TAP_MODE_NONE),
      event_before_or_above_starting_gesture_event_(false) {
  DCHECK(listener_);
  span_slop_ = config.span_slop + kSlopEpsilon;
  touch_min_major_ = config.min_scaling_touch_major;
  touch_max_major_ = std::min(config.min_scaling_span / std::sqrt(2.f),
                              2.f * touch_min_major_);
  min_span_ = config.min_scaling_span + kSlopEpsilon;
  ResetTouchHistory();
}

ScaleGestureDetector::~ScaleGestureDetector() {}

bool ScaleGestureDetector::OnTouchEvent(const MotionEvent& event) {
  curr_time_ = event.GetEventTime();

  const int action = event.GetAction();

  const bool stream_complete =
      action == MotionEvent::ACTION_UP ||
      action == MotionEvent::ACTION_CANCEL ||
      (action == MotionEvent::ACTION_POINTER_DOWN && InDoubleTapMode());

  if (action == MotionEvent::ACTION_DOWN || stream_complete) {
    // Reset any scale in progress with the listener.
    // If it's an ACTION_DOWN we're beginning a new event stream.
    // This means the app probably didn't give us all the events. Shame on it.
    if (in_progress_) {
      listener_->OnScaleEnd(*this, event);
      ResetScaleWithSpan(0);
    } else if (InDoubleTapMode() && stream_complete) {
      ResetScaleWithSpan(0);
    }

    if (stream_complete) {
      ResetTouchHistory();
      return true;
    }
  }

  const bool config_changed = action == MotionEvent::ACTION_DOWN ||
                              action == MotionEvent::ACTION_POINTER_UP ||
                              action == MotionEvent::ACTION_POINTER_DOWN;

  const bool pointer_up = action == MotionEvent::ACTION_POINTER_UP;
  const int skip_index = pointer_up ? event.GetActionIndex() : -1;

  // Determine focal point.
  float sum_x = 0, sum_y = 0;
  const int count = static_cast<int>(event.GetPointerCount());
  const int unreleased_point_count = pointer_up ? count - 1 : count;
  const float inverse_unreleased_point_count = 1.0f / unreleased_point_count;

  float focus_x;
  float focus_y;
  if (InDoubleTapMode()) {
    // In double tap mode, the focal pt is always where the double tap
    // gesture started.
    focus_x = double_tap_focus_x_;
    focus_y = double_tap_focus_y_;
    if (event.GetY() < focus_y) {
      event_before_or_above_starting_gesture_event_ = true;
    } else {
      event_before_or_above_starting_gesture_event_ = false;
    }
  } else {
    for (int i = 0; i < count; i++) {
      if (skip_index == i)
        continue;
      sum_x += event.GetX(i);
      sum_y += event.GetY(i);
    }

    focus_x = sum_x * inverse_unreleased_point_count;
    focus_y = sum_y * inverse_unreleased_point_count;
  }

  AddTouchHistory(event);

  // Determine average deviation from focal point.
  float dev_sum_x = 0, dev_sum_y = 0;
  for (int i = 0; i < count; i++) {
    if (skip_index == i)
      continue;

    dev_sum_x += std::abs(event.GetX(i) - focus_x);
    dev_sum_y += std::abs(event.GetY(i) - focus_y);
  }
  // Convert the resulting diameter into a radius, to include touch
  // radius in overall deviation.
  const float touch_radius = touch_history_last_accepted_ / 2;

  const float dev_x = dev_sum_x * inverse_unreleased_point_count + touch_radius;
  const float dev_y = dev_sum_y * inverse_unreleased_point_count + touch_radius;

  // Span is the average distance between touch points through the focal point;
  // i.e. the diameter of the circle with a radius of the average deviation from
  // the focal point.
  const float span_x = dev_x * 2;
  const float span_y = dev_y * 2;
  float span;
  if (InDoubleTapMode()) {
    span = span_y;
  } else {
    span = std::sqrt(span_x * span_x + span_y * span_y);
  }

  // Dispatch begin/end events as needed.
  // If the configuration changes, notify the app to reset its current state by
  // beginning a fresh scale event stream.
  const bool was_in_progress = in_progress_;
  focus_x_ = focus_x;
  focus_y_ = focus_y;
  if (!InDoubleTapMode() && in_progress_ &&
      (span < min_span_ || config_changed)) {
    listener_->OnScaleEnd(*this, event);
    ResetScaleWithSpan(span);
  }
  if (config_changed) {
    prev_span_x_ = curr_span_x_ = span_x;
    prev_span_y_ = curr_span_y_ = span_y;
    initial_span_ = prev_span_ = curr_span_ = span;
  }

  const float min_span = InDoubleTapMode() ? span_slop_ : min_span_;
  if (!in_progress_ && span >= min_span &&
      (was_in_progress || std::abs(span - initial_span_) > span_slop_)) {
    prev_span_x_ = curr_span_x_ = span_x;
    prev_span_y_ = curr_span_y_ = span_y;
    prev_span_ = curr_span_ = span;
    prev_time_ = curr_time_;
    in_progress_ = listener_->OnScaleBegin(*this, event);
  }

  // Handle motion; focal point and span/scale factor are changing.
  if (action == MotionEvent::ACTION_MOVE) {
    curr_span_x_ = span_x;
    curr_span_y_ = span_y;
    curr_span_ = span;

    bool update_prev = true;

    if (in_progress_) {
      update_prev = listener_->OnScale(*this, event);
    }

    if (update_prev) {
      prev_span_x_ = curr_span_x_;
      prev_span_y_ = curr_span_y_;
      prev_span_ = curr_span_;
      prev_time_ = curr_time_;
    }
  }

  return true;
}

bool ScaleGestureDetector::IsInProgress() const { return in_progress_; }

bool ScaleGestureDetector::InDoubleTapMode() const {
  return double_tap_mode_ == DOUBLE_TAP_MODE_IN_PROGRESS;
}

float ScaleGestureDetector::GetFocusX() const { return focus_x_; }

float ScaleGestureDetector::GetFocusY() const { return focus_y_; }

float ScaleGestureDetector::GetCurrentSpan() const { return curr_span_; }

float ScaleGestureDetector::GetCurrentSpanX() const { return curr_span_x_; }

float ScaleGestureDetector::GetCurrentSpanY() const { return curr_span_y_; }

float ScaleGestureDetector::GetPreviousSpan() const { return prev_span_; }

float ScaleGestureDetector::GetPreviousSpanX() const { return prev_span_x_; }

float ScaleGestureDetector::GetPreviousSpanY() const { return prev_span_y_; }

float ScaleGestureDetector::GetScaleFactor() const {
  if (InDoubleTapMode()) {
    // Drag is moving up; the further away from the gesture start, the smaller
    // the span should be, the closer, the larger the span, and therefore the
    // larger the scale.
    const bool scale_up = (event_before_or_above_starting_gesture_event_ &&
                           (curr_span_ < prev_span_)) ||
                          (!event_before_or_above_starting_gesture_event_ &&
                           (curr_span_ > prev_span_));
    const float span_diff =
        (std::abs(1.f - (curr_span_ / prev_span_)) * kScaleFactor);
    return prev_span_ <= 0 ? 1.f
                           : (scale_up ? (1.f + span_diff) : (1.f - span_diff));
  }
  return prev_span_ > 0 ? curr_span_ / prev_span_ : 1;
}

base::TimeDelta ScaleGestureDetector::GetTimeDelta() const {
  return curr_time_ - prev_time_;
}

base::TimeTicks ScaleGestureDetector::GetEventTime() const {
  return curr_time_;
}

bool ScaleGestureDetector::OnDoubleTap(const MotionEvent& ev) {
  // Double tap: start watching for a swipe.
  double_tap_focus_x_ = ev.GetX();
  double_tap_focus_y_ = ev.GetY();
  double_tap_mode_ = DOUBLE_TAP_MODE_IN_PROGRESS;
  return true;
}

void ScaleGestureDetector::AddTouchHistory(const MotionEvent& ev) {
  const base::TimeTicks current_time = ev.GetEventTime();
  DCHECK(!current_time.is_null());
  const int count = static_cast<int>(ev.GetPointerCount());
  bool accept = touch_history_last_accepted_time_.is_null() ||
                (current_time - touch_history_last_accepted_time_) >=
                    base::TimeDelta::FromMilliseconds(kTouchStabilizeTimeMs);
  float total = 0;
  int sample_count = 0;
  for (int i = 0; i < count; i++) {
    const bool has_last_accepted = !std::isnan(touch_history_last_accepted_);
    const int history_size = static_cast<int>(ev.GetHistorySize());
    const int pointersample_count = history_size + 1;
    for (int h = 0; h < pointersample_count; h++) {
      float major;
      if (h < history_size) {
        major = ev.GetHistoricalTouchMajor(i, h);
      } else {
        major = ev.GetTouchMajor(i);
      }
      if (major < touch_min_major_)
        major = touch_min_major_;
      if (major > touch_max_major_)
        major = touch_max_major_;
      total += major;

      if (std::isnan(touch_upper_) || major > touch_upper_) {
        touch_upper_ = major;
      }
      if (std::isnan(touch_lower_) || major < touch_lower_) {
        touch_lower_ = major;
      }

      if (has_last_accepted) {
        const float major_delta = major - touch_history_last_accepted_;
        const int direction_sig =
            major_delta > 0 ? 1 : (major_delta < 0 ? -1 : 0);
        if (direction_sig != touch_history_direction_ ||
            (direction_sig == 0 && touch_history_direction_ == 0)) {
          touch_history_direction_ = direction_sig;
          touch_history_last_accepted_time_ = h < history_size
                                                  ? ev.GetHistoricalEventTime(h)
                                                  : ev.GetEventTime();
          accept = false;
        }
      }
    }
    sample_count += pointersample_count;
  }

  const float avg = total / sample_count;

  if (accept) {
    float new_accepted = (touch_upper_ + touch_lower_ + avg) / 3;
    touch_upper_ = (touch_upper_ + new_accepted) / 2;
    touch_lower_ = (touch_lower_ + new_accepted) / 2;
    touch_history_last_accepted_ = new_accepted;
    touch_history_direction_ = 0;
    touch_history_last_accepted_time_ = ev.GetEventTime();
  }
}

void ScaleGestureDetector::ResetTouchHistory() {
  touch_upper_ = std::numeric_limits<float>::quiet_NaN();
  touch_lower_ = std::numeric_limits<float>::quiet_NaN();
  touch_history_last_accepted_ = std::numeric_limits<float>::quiet_NaN();
  touch_history_direction_ = 0;
  touch_history_last_accepted_time_ = base::TimeTicks();
}

void ScaleGestureDetector::ResetScaleWithSpan(float span) {
  in_progress_ = false;
  initial_span_ = span;
  double_tap_mode_ = DOUBLE_TAP_MODE_NONE;
}

}  // namespace ui
