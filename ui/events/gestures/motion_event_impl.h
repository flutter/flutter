// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_UI_MOTION_EVENT_H_
#define UI_EVENTS_GESTURE_DETECTION_UI_MOTION_EVENT_H_

#include <map>

#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "ui/events/event.h"
#include "ui/events/events_export.h"
#include "ui/events/gesture_detection/motion_event.h"

namespace ui {

// Implementation of MotionEvent which takes a stream of ui::TouchEvents.
class EVENTS_EXPORT MotionEventImpl : public MotionEvent {
 public:
  MotionEventImpl();
  ~MotionEventImpl() override;

  void OnTouch(const TouchEvent& touch);

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

  int GetSourceDeviceId(size_t pointer_index) const;

  // We can't cleanup removed touch points immediately upon receipt of a
  // TouchCancel or TouchRelease, as the MotionEvent needs to be able to report
  // information about those touch events. Once the MotionEvent has been
  // processed, we call CleanupRemovedTouchPoints to do the required
  // book-keeping.
  void CleanupRemovedTouchPoints(const TouchEvent& event);

 private:
  struct PointData {
    PointData();
    float x;
    float y;
    float raw_x;
    float raw_y;
    int touch_id;
    float pressure;
    int source_device_id;
    float touch_major;
    float touch_minor;
    float orientation;
  };

  MotionEventImpl(
      size_t pointer_count,
      const base::TimeTicks& last_touch_time,
      Action cached_action,
      int cached_action_index,
      int flags,
      const PointData (&active_touches)[MotionEvent::MAX_TOUCH_POINT_COUNT]);

  static PointData GetPointDataFromTouchEvent(const TouchEvent& touch);
  void AddTouch(const TouchEvent& touch);
  void UpdateTouch(const TouchEvent& touch);
  void UpdateCachedAction(const TouchEvent& touch);
  size_t GetIndexFromId(int id) const;

  size_t pointer_count_;
  base::TimeTicks last_touch_time_;
  Action cached_action_;
  // The index of the touch responsible for last ACTION_POINTER_DOWN or
  // ACTION_POINTER_UP. -1 if no such action has occurred.
  int cached_action_index_;
  int flags_;

  // We want constant time indexing by pointer_index, and fast indexing by id.
  PointData active_touches_[MotionEvent::MAX_TOUCH_POINT_COUNT];

  DISALLOW_COPY_AND_ASSIGN(MotionEventImpl);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_UI_MOTION_EVENT_H_
