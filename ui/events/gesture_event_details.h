// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DETAILS_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DETAILS_H_

#include "base/logging.h"
#include "ui/events/event_constants.h"
#include "ui/events/events_base_export.h"
#include "ui/gfx/rect.h"
#include "ui/gfx/rect_conversions.h"

namespace ui {

struct EVENTS_BASE_EXPORT GestureEventDetails {
 public:
  GestureEventDetails();
  explicit GestureEventDetails(EventType type);
  GestureEventDetails(EventType type, float delta_x, float delta_y);

  EventType type() const { return type_; }

  int touch_points() const { return touch_points_; }
  void set_touch_points(int touch_points) {
    DCHECK_GT(touch_points, 0);
    touch_points_ = touch_points;
  }

  int oldest_touch_id() const { return oldest_touch_id_; }
  void set_oldest_touch_id(int oldest_touch_id) {
    DCHECK_GE(oldest_touch_id, 0);
    oldest_touch_id_ = oldest_touch_id;
  }

  // TODO(tdresser): Return RectF. See crbug.com/337824.
  const gfx::Rect bounding_box() const {
    return ToEnclosingRect(bounding_box_);
  }

  const gfx::RectF& bounding_box_f() const {
    return bounding_box_;
  }

  void set_bounding_box(const gfx::RectF& box) { bounding_box_ = box; }

  float scroll_x_hint() const {
    DCHECK_EQ(ET_GESTURE_SCROLL_BEGIN, type_);
    return data.scroll_begin.x_hint;
  }

  float scroll_y_hint() const {
    DCHECK_EQ(ET_GESTURE_SCROLL_BEGIN, type_);
    return data.scroll_begin.y_hint;
  }

  float scroll_x() const {
    DCHECK_EQ(ET_GESTURE_SCROLL_UPDATE, type_);
    return data.scroll_update.x;
  }

  float scroll_y() const {
    DCHECK_EQ(ET_GESTURE_SCROLL_UPDATE, type_);
    return data.scroll_update.y;
  }

  float velocity_x() const {
    DCHECK_EQ(ET_SCROLL_FLING_START, type_);
    return data.fling_velocity.x;
  }

  float velocity_y() const {
    DCHECK_EQ(ET_SCROLL_FLING_START, type_);
    return data.fling_velocity.y;
  }

  float first_finger_width() const {
    DCHECK_EQ(ET_GESTURE_TWO_FINGER_TAP, type_);
    return data.first_finger_enclosing_rectangle.width;
  }

  float first_finger_height() const {
    DCHECK_EQ(ET_GESTURE_TWO_FINGER_TAP, type_);
    return data.first_finger_enclosing_rectangle.height;
  }

  float scale() const {
    DCHECK_EQ(ET_GESTURE_PINCH_UPDATE, type_);
    return data.scale;
  }

  bool swipe_left() const {
    DCHECK_EQ(ET_GESTURE_SWIPE, type_);
    return data.swipe.left;
  }

  bool swipe_right() const {
    DCHECK_EQ(ET_GESTURE_SWIPE, type_);
    return data.swipe.right;
  }

  bool swipe_up() const {
    DCHECK_EQ(ET_GESTURE_SWIPE, type_);
    return data.swipe.up;
  }

  bool swipe_down() const {
    DCHECK_EQ(ET_GESTURE_SWIPE, type_);
    return data.swipe.down;
  }

  int tap_count() const {
    DCHECK(type_ == ET_GESTURE_TAP ||
           type_ == ET_GESTURE_TAP_UNCONFIRMED ||
           type_ == ET_GESTURE_DOUBLE_TAP);
    return data.tap_count;
  }

  void set_tap_count(int tap_count) {
    DCHECK_GE(tap_count, 0);
    DCHECK(type_ == ET_GESTURE_TAP ||
           type_ == ET_GESTURE_TAP_UNCONFIRMED ||
           type_ == ET_GESTURE_DOUBLE_TAP);
    data.tap_count = tap_count;
  }

  void set_scale(float scale) {
    DCHECK_GE(scale, 0.0f);
    DCHECK_EQ(type_, ET_GESTURE_PINCH_UPDATE);
    data.scale = scale;
  }

 private:
  EventType type_;
  union Details {
    Details();
    struct {  // SCROLL start details.
      // Distance that caused the scroll to start.  Generally redundant with
      // the x/y values from the first scroll_update.
      float x_hint;
      float y_hint;
    } scroll_begin;

    struct {  // SCROLL delta.
      float x;
      float y;
    } scroll_update;

    float scale;  // PINCH scale.

    struct {  // FLING velocity.
      float x;
      float y;
    } fling_velocity;

    // Dimensions of the first finger's enclosing rectangle for
    // TWO_FINGER_TAP.
    struct {
      float width;
      float height;
    } first_finger_enclosing_rectangle;

    struct {  // SWIPE direction.
      bool left;
      bool right;
      bool up;
      bool down;
    } swipe;

    // Tap information must be set for ET_GESTURE_TAP,
    // ET_GESTURE_TAP_UNCONFIRMED, and ET_GESTURE_DOUBLE_TAP events.
    int tap_count;  // TAP repeat count.
  } data;

  int touch_points_;  // Number of active touch points in the gesture.

  // Bounding box is an axis-aligned rectangle that contains all the
  // enclosing rectangles of the touch-points in the gesture.
  gfx::RectF bounding_box_;

  // The touch id of the oldest touch contributing to the gesture.
  int oldest_touch_id_;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DETAILS_H_
