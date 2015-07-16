// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_MOTION_EVENT_H_
#define UI_EVENTS_GESTURE_DETECTION_MOTION_EVENT_H_

#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"

namespace ui {

// Abstract class for a generic motion-related event, patterned after that
// subset of Android's MotionEvent API used in gesture detection.
class GESTURE_DETECTION_EXPORT MotionEvent {
 public:
  enum Action {
    ACTION_DOWN,
    ACTION_UP,
    ACTION_MOVE,
    ACTION_CANCEL,
    ACTION_POINTER_DOWN,
    ACTION_POINTER_UP,
  };

  enum ToolType {
    TOOL_TYPE_UNKNOWN,
    TOOL_TYPE_FINGER,
    TOOL_TYPE_STYLUS,
    TOOL_TYPE_MOUSE,
    TOOL_TYPE_ERASER
  };

  enum ButtonType {
    BUTTON_PRIMARY = 1 << 0,
    BUTTON_SECONDARY = 1 << 1,
    BUTTON_TERTIARY = 1 << 2,
    BUTTON_BACK = 1 << 3,
    BUTTON_FORWARD = 1 << 4,
  };

  // The implementer promises that |GetPointerId()| will never exceed
  // MAX_POINTER_ID.
  enum { MAX_POINTER_ID = 31, MAX_TOUCH_POINT_COUNT = 16 };

  virtual ~MotionEvent() {}

  virtual int GetId() const = 0;
  virtual Action GetAction() const = 0;
  // Only valid if |GetAction()| returns ACTION_POINTER_UP or
  // ACTION_POINTER_DOWN.
  virtual int GetActionIndex() const = 0;
  virtual size_t GetPointerCount() const = 0;
  virtual int GetPointerId(size_t pointer_index) const = 0;
  virtual float GetX(size_t pointer_index) const = 0;
  virtual float GetY(size_t pointer_index) const = 0;
  virtual float GetRawX(size_t pointer_index) const = 0;
  virtual float GetRawY(size_t pointer_index) const = 0;
  virtual float GetTouchMajor(size_t pointer_index) const = 0;
  virtual float GetTouchMinor(size_t pointer_index) const = 0;
  virtual float GetOrientation(size_t pointer_index) const = 0;
  virtual float GetPressure(size_t pointer_index) const = 0;
  virtual ToolType GetToolType(size_t pointer_index) const = 0;
  virtual int GetButtonState() const = 0;
  virtual int GetFlags() const = 0;
  virtual base::TimeTicks GetEventTime() const = 0;

  // Optional historical data, default implementation provides an empty history.
  virtual size_t GetHistorySize() const;
  virtual base::TimeTicks GetHistoricalEventTime(size_t historical_index) const;
  virtual float GetHistoricalTouchMajor(size_t pointer_index,
                                        size_t historical_index) const;
  virtual float GetHistoricalX(size_t pointer_index,
                               size_t historical_index) const;
  virtual float GetHistoricalY(size_t pointer_index,
                               size_t historical_index) const;

  virtual scoped_ptr<MotionEvent> Clone() const = 0;
  virtual scoped_ptr<MotionEvent> Cancel() const = 0;

  float GetX() const { return GetX(0); }
  float GetY() const { return GetY(0); }
  float GetRawX() const { return GetRawX(0); }
  float GetRawY() const { return GetRawY(0); }
  float GetRawOffsetX() const { return GetRawX() - GetX(); }
  float GetRawOffsetY() const { return GetRawY() - GetY(); }

  float GetTouchMajor() const { return GetTouchMajor(0); }
  float GetTouchMinor() const { return GetTouchMinor(0); }

  // Returns the orientation of the major axis clockwise from vertical, in
  // radians. The return value lies in [-PI/2, PI/2].
  float GetOrientation() const { return GetOrientation(0); }

  float GetPressure() const { return GetPressure(0); }
  ToolType GetToolType() const { return GetToolType(0); }

  // O(N) search of pointers (use sparingly!). Returns -1 if |id| nonexistent.
  int FindPointerIndexOfId(int id) const;
};

GESTURE_DETECTION_EXPORT bool operator==(const MotionEvent& lhs,
                                         const MotionEvent& rhs);
GESTURE_DETECTION_EXPORT bool operator!=(const MotionEvent& lhs,
                                         const MotionEvent& rhs);

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_MOTION_EVENT_H_
