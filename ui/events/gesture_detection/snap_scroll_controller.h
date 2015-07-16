// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_SNAP_SCROLL_CONTROLLER_H_
#define UI_EVENTS_GESTURE_DETECTION_SNAP_SCROLL_CONTROLLER_H_

#include "base/basictypes.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"

namespace gfx {
class Display;
}

namespace ui {

class MotionEvent;
class ZoomManager;

// Port of SnapScrollController.java from Chromium
// Controls the scroll snapping behavior based on scroll updates.
class SnapScrollController {
 public:
  explicit SnapScrollController(const gfx::Display& display);
  ~SnapScrollController();

  // Updates the snap scroll mode based on the given X and Y distance to be
  // moved on scroll.  If the scroll update is above a threshold, the snapping
  // behavior is reset.
  void UpdateSnapScrollMode(float distance_x, float distance_y);

  // Sets the snap scroll mode based on the event type.
  void SetSnapScrollingMode(const MotionEvent& event,
                            bool is_scale_gesture_detection_in_progress);

  void ResetSnapScrollMode() { snap_scroll_mode_ = SNAP_NONE; }
  bool IsSnapVertical() const { return snap_scroll_mode_ == SNAP_VERT; }
  bool IsSnapHorizontal() const { return snap_scroll_mode_ == SNAP_HORIZ; }
  bool IsSnappingScrolls() const { return snap_scroll_mode_ != SNAP_NONE; }

 private:
  enum SnapMode {
    SNAP_NONE,
    SNAP_HORIZ,
    SNAP_VERT
  };

  float channel_distance_;
  SnapMode snap_scroll_mode_;
  float first_touch_x_;
  float first_touch_y_;
  float distance_x_;
  float distance_y_;

  DISALLOW_COPY_AND_ASSIGN(SnapScrollController);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_SNAP_SCROLL_CONTROLLER_H_
