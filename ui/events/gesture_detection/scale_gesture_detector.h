// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_SCALE_GESTURE_DETECTOR_H_
#define UI_EVENTS_GESTURE_DETECTION_SCALE_GESTURE_DETECTOR_H_

#include "base/time/time.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"

namespace ui {

class MotionEvent;
class ScaleGestureListener;

// Port of ScaleGestureDetector.java from Android
// * platform/frameworks/base/core/java/android/view/ScaleGestureDetector.java
// * Change-Id: I3e7926a4f6f9ab4951f380bd004499c78b3bda69
// * Please update the Change-Id as upstream Android changes are pulled.
class GESTURE_DETECTION_EXPORT ScaleGestureDetector {
 public:
  struct GESTURE_DETECTION_EXPORT Config {
    Config();
    ~Config();

    // Distance the current span can deviate from the initial span before
    // scaling will start (in dips). The span is the diameter of the circle with
    // a radius of average pointer deviation from the focal point.
    float span_slop;

    // Minimum accepted value for TouchMajor while scaling (in dips).
    float min_scaling_touch_major;

    // Minimum span needed to initiate a scaling gesture (in dips).
    float min_scaling_span;

    // Minimum pinch span change before pinch occurs (in dips). See
    // crbug.com/373318.
    float min_pinch_update_span_delta;
  };

  ScaleGestureDetector(const Config& config, ScaleGestureListener* listener);
  virtual ~ScaleGestureDetector();

  // Accepts MotionEvents and dispatches events to a |ScaleGestureListener|
  // when appropriate.
  //
  // Note: Applications should pass a complete and consistent event stream to
  // this method. A complete and consistent event stream involves all
  // MotionEvents from the initial ACTION_DOWN to the final ACTION_UP or
  // ACTION_CANCEL.
  //
  // Returns true if the event was processed and the detector wants to receive
  // the rest of the MotionEvents in this event stream.
  bool OnTouchEvent(const MotionEvent& event);

  // This method may be called by the owner when a a double-tap event has been
  // detected *for the same event stream* being fed to this instance of the
  // ScaleGestureDetector. As call order is important here, the double-tap
  // detector should always be offered events *before* the ScaleGestureDetector.
  bool OnDoubleTap(const MotionEvent& event);

  // Set whether the associated |ScaleGestureListener| should receive
  // OnScale callbacks when the user performs a doubletap followed by a swipe.
  bool IsInProgress() const;
  bool InDoubleTapMode() const;
  float GetFocusX() const;
  float GetFocusY() const;
  float GetCurrentSpan() const;
  float GetCurrentSpanX() const;
  float GetCurrentSpanY() const;
  float GetPreviousSpan() const;
  float GetPreviousSpanX() const;
  float GetPreviousSpanY() const;
  float GetScaleFactor() const;
  base::TimeDelta GetTimeDelta() const;
  base::TimeTicks GetEventTime() const;

 private:
  enum DoubleTapMode { DOUBLE_TAP_MODE_NONE, DOUBLE_TAP_MODE_IN_PROGRESS };

  // The TouchMajor/TouchMinor elements of a MotionEvent can flutter/jitter on
  // some hardware/driver combos. Smooth out to get kinder, gentler behavior.
  void AddTouchHistory(const MotionEvent& ev);
  void ResetTouchHistory();

  void ResetScaleWithSpan(float span);

  ScaleGestureListener* const listener_;

  float focus_x_;
  float focus_y_;
  float curr_span_;
  float prev_span_;
  float initial_span_;
  float curr_span_x_;
  float curr_span_y_;
  float prev_span_x_;
  float prev_span_y_;
  base::TimeTicks curr_time_;
  base::TimeTicks prev_time_;
  bool in_progress_;
  float span_slop_;
  float min_span_;

  // Bounds for recently seen values.
  float touch_upper_;
  float touch_lower_;
  float touch_history_last_accepted_;
  int touch_history_direction_;
  base::TimeTicks touch_history_last_accepted_time_;
  float touch_min_major_;
  float touch_max_major_;
  float double_tap_focus_x_;
  float double_tap_focus_y_;
  DoubleTapMode double_tap_mode_;

  bool event_before_or_above_starting_gesture_event_;

  DISALLOW_COPY_AND_ASSIGN(ScaleGestureDetector);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_SCALE_GESTURE_DETECTOR_H_
