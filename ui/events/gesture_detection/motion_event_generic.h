// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_UI_MOTION_EVENT_GENERIC_H_
#define UI_EVENTS_GESTURE_DETECTION_UI_MOTION_EVENT_GENERIC_H_

#include "base/basictypes.h"
#include "base/containers/stack_container.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"
#include "ui/events/gesture_detection/motion_event.h"

namespace ui {

struct GESTURE_DETECTION_EXPORT PointerProperties {
  PointerProperties();
  PointerProperties(float x, float y);

  int id;
  MotionEvent::ToolType tool_type;
  float x;
  float y;
  float raw_x;
  float raw_y;
  float pressure;
  float touch_major;
  float touch_minor;
  float orientation;
};

// A generic MotionEvent implementation.
class GESTURE_DETECTION_EXPORT MotionEventGeneric : public MotionEvent {
 public:
  MotionEventGeneric(Action action,
                     base::TimeTicks event_time,
                     const PointerProperties& pointer);
  MotionEventGeneric(const MotionEventGeneric& other);

  ~MotionEventGeneric() override;

  // MotionEvent implementation.
  int GetId() const override;
  Action GetAction() const override;
  int GetActionIndex() const override;
  size_t GetPointerCount() const override;
  int GetPointerId(size_t pointer_index) const override;
  float GetX(size_t pointer_index) const override;
  float GetY(size_t pointer_index) const override;
  float GetRawX(size_t pointer_index) const override;
  float GetRawY(size_t pointer_index) const override;
  float GetTouchMajor(size_t pointer_index) const override;
  float GetTouchMinor(size_t pointer_index) const override;
  float GetOrientation(size_t pointer_index) const override;
  float GetPressure(size_t pointer_index) const override;
  ToolType GetToolType(size_t pointer_index) const override;
  int GetButtonState() const override;
  int GetFlags() const override;
  base::TimeTicks GetEventTime() const override;
  scoped_ptr<MotionEvent> Clone() const override;
  scoped_ptr<MotionEvent> Cancel() const override;

  void PushPointer(const PointerProperties& pointer);

  void set_action(Action action) { action_ = action; }
  void set_event_time(base::TimeTicks event_time) { event_time_ = event_time; }
  void set_id(int id) { id_ = id; }
  void set_action_index(int action_index) { action_index_ = action_index; }
  void set_button_state(int button_state) { button_state_ = button_state; }
  void set_flags(int flags) { flags_ = flags; }

 protected:
  MotionEventGeneric();

  void PopPointer();

  PointerProperties& pointer(size_t index) { return pointers_[index]; }
  const PointerProperties& pointer(size_t index) const {
    return pointers_[index];
  }

 private:
  enum { kTypicalMaxPointerCount = 5 };

  Action action_;
  base::TimeTicks event_time_;
  int id_;
  int action_index_;
  int button_state_;
  int flags_;
  base::StackVector<PointerProperties, kTypicalMaxPointerCount> pointers_;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_UI_MOTION_EVENT_GENERIC_H_
