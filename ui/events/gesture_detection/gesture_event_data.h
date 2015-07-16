// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DATA_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DATA_H_

#include "base/time/time.h"
#include "ui/events/event_constants.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"
#include "ui/events/gesture_detection/motion_event.h"
#include "ui/events/gesture_event_details.h"

namespace ui {

class GestureEventDataPacket;

struct GESTURE_DETECTION_EXPORT GestureEventData {
  GestureEventData(const GestureEventDetails&,
                   int motion_event_id,
                   MotionEvent::ToolType primary_tool_type,
                   base::TimeTicks time,
                   float x,
                   float y,
                   float raw_x,
                   float raw_y,
                   size_t touch_point_count,
                   const gfx::RectF& bounding_box,
                   int flags);
  GestureEventData(EventType type, const GestureEventData&);

  EventType type() const { return details.type(); }

  GestureEventDetails details;
  int motion_event_id;
  MotionEvent::ToolType primary_tool_type;
  base::TimeTicks time;
  float x;
  float y;
  float raw_x;
  float raw_y;
  int flags;

 private:
  friend class GestureEventDataPacket;

  // Initializes type to GESTURE_TYPE_INVALID.
  GestureEventData();
};

}  //  namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_EVENT_DATA_H_
