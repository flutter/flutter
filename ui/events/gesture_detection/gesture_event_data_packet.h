// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DATA_PACKET_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DATA_PACKET_H_

#include "base/containers/stack_container.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"
#include "ui/events/gesture_detection/gesture_event_data.h"

namespace ui {

class MotionEvent;

// Acts as a transport container for gestures created (directly or indirectly)
// by a touch event.
class GESTURE_DETECTION_EXPORT GestureEventDataPacket {
 public:
  enum GestureSource {
    UNDEFINED = -1,        // Used only for a default-constructed packet.
    INVALID,               // The source of the gesture was invalid.
    TOUCH_SEQUENCE_START,  // The start of a new gesture sequence.
    TOUCH_SEQUENCE_END,    // The end of a gesture sequence.
    TOUCH_SEQUENCE_CANCEL, // The gesture sequence was cancelled.
    TOUCH_START,           // A touch down occured during a gesture sequence.
    TOUCH_MOVE,            // A touch move occured during a gesture sequence.
    TOUCH_END,             // A touch up occured during a gesture sequence.
    TOUCH_TIMEOUT,         // Timeout from an existing gesture sequence.
  };

  GestureEventDataPacket();
  GestureEventDataPacket(const GestureEventDataPacket& other);
  ~GestureEventDataPacket();
  GestureEventDataPacket& operator=(const GestureEventDataPacket& other);

  // Factory methods for creating a packet from a particular event.
  static GestureEventDataPacket FromTouch(const ui::MotionEvent& touch);
  static GestureEventDataPacket FromTouchTimeout(
      const GestureEventData& gesture);

  void Push(const GestureEventData& gesture);

  const base::TimeTicks& timestamp() const { return timestamp_; }
  const GestureEventData& gesture(size_t i) const { return gestures_[i]; }
  size_t gesture_count() const { return gestures_->size(); }
  GestureSource gesture_source() const { return gesture_source_; }
  const gfx::PointF& touch_location() const { return touch_location_; }
  const gfx::PointF& raw_touch_location() const { return raw_touch_location_; }

 private:
  GestureEventDataPacket(base::TimeTicks timestamp,
                         GestureSource source,
                         const gfx::PointF& touch_location,
                         const gfx::PointF& raw_touch_location);

  enum { kTypicalMaxGesturesPerTouch = 5 };
  base::TimeTicks timestamp_;
  base::StackVector<GestureEventData, kTypicalMaxGesturesPerTouch> gestures_;
  gfx::PointF touch_location_;
  gfx::PointF raw_touch_location_;
  GestureSource gesture_source_;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DATA_PACKET_H_
