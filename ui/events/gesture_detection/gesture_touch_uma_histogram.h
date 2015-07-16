// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_TOUCH_UMA_HISTOGRAM_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_TOUCH_UMA_HISTOGRAM_H_

#include "base/time/time.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"
#include "ui/events/gesture_detection/gesture_event_data.h"
#include "ui/events/gesture_detection/motion_event.h"

namespace ui {

enum UMAEventType {
  // WARNING: Do not change the numerical values of any of these types.
  // Do not remove deprecated types - just comment them as deprecated.
  UMA_ET_UNKNOWN = 0,
  UMA_ET_TOUCH_RELEASED = 1,
  UMA_ET_TOUCH_PRESSED = 2,
  UMA_ET_TOUCH_MOVED = 3,
  UMA_ET_TOUCH_STATIONARY = 4,  // Deprecated. Do not remove.
  UMA_ET_TOUCH_CANCELLED = 5,
  UMA_ET_GESTURE_SCROLL_BEGIN = 6,
  UMA_ET_GESTURE_SCROLL_END = 7,
  UMA_ET_GESTURE_SCROLL_UPDATE = 8,
  UMA_ET_GESTURE_TAP = 9,
  UMA_ET_GESTURE_TAP_DOWN = 10,
  UMA_ET_GESTURE_BEGIN = 11,
  UMA_ET_GESTURE_END = 12,
  UMA_ET_GESTURE_DOUBLE_TAP = 13,
  UMA_ET_GESTURE_TRIPLE_TAP = 14,
  UMA_ET_GESTURE_TWO_FINGER_TAP = 15,
  UMA_ET_GESTURE_PINCH_BEGIN = 16,
  UMA_ET_GESTURE_PINCH_END = 17,
  UMA_ET_GESTURE_PINCH_UPDATE = 18,
  UMA_ET_GESTURE_LONG_PRESS = 19,
  UMA_ET_GESTURE_SWIPE_2 = 20,  // Swipe with 2 fingers
  UMA_ET_SCROLL = 21,
  UMA_ET_SCROLL_FLING_START = 22,
  UMA_ET_SCROLL_FLING_CANCEL = 23,
  UMA_ET_GESTURE_SWIPE_3 = 24,   // Swipe with 3 fingers
  UMA_ET_GESTURE_SWIPE_4P = 25,  // Swipe with 4+ fingers
  UMA_ET_GESTURE_SCROLL_UPDATE_2 = 26,
  UMA_ET_GESTURE_SCROLL_UPDATE_3 = 27,
  UMA_ET_GESTURE_SCROLL_UPDATE_4P = 28,
  UMA_ET_GESTURE_PINCH_UPDATE_3 = 29,
  UMA_ET_GESTURE_PINCH_UPDATE_4P = 30,
  UMA_ET_GESTURE_LONG_TAP = 31,
  UMA_ET_GESTURE_SHOW_PRESS = 32,
  UMA_ET_GESTURE_TAP_CANCEL = 33,
  UMA_ET_GESTURE_WIN8_EDGE_SWIPE = 34,
  UMA_ET_GESTURE_SWIPE_1 = 35,  // Swipe with 1 finger
  UMA_ET_GESTURE_TAP_UNCONFIRMED = 36,
  // NOTE: Add new event types only immediately above this line. Make sure to
  // update the UIEventType enum in tools/metrics/histograms/histograms.xml
  // accordingly.
  UMA_ET_COUNT
};

// Records some touch/gesture event specific details (e.g. what gestures are
// targetted to which components etc.)
class GESTURE_DETECTION_EXPORT GestureTouchUMAHistogram {
 public:
  GestureTouchUMAHistogram();
  ~GestureTouchUMAHistogram();

  static void RecordGestureEvent(const ui::GestureEventData& gesture);
  void RecordTouchEvent(const ui::MotionEvent& event);

 private:
  static UMAEventType UMAEventTypeFromEvent(const GestureEventData& gesture);

  // The first finger's press time.
  base::TimeTicks start_time_;
  // The first finger's press location.
  gfx::Point start_touch_position_;
  // The maximum distance the first touch point travelled from its starting
  // location in pixels.
  float max_distance_from_start_squared_;
  bool is_single_finger_;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_TOUCH_UMA_HISTOGRAM_H_
