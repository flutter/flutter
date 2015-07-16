// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// MSVC++ requires this to be set before any other includes to get M_PI.
#define _USE_MATH_DEFINES

#include "ui/events/gestures/motion_event_impl.h"

#include <cmath>

#include "base/logging.h"
#include "ui/events/gestures/gesture_configuration.h"

namespace ui {

MotionEventImpl::MotionEventImpl()
    : pointer_count_(0), cached_action_index_(-1) {
}

MotionEventImpl::MotionEventImpl(
    size_t pointer_count,
    const base::TimeTicks& last_touch_time,
    Action cached_action,
    int cached_action_index,
    int flags,
    const PointData (&active_touches)[MotionEvent::MAX_TOUCH_POINT_COUNT])
    : pointer_count_(pointer_count),
      last_touch_time_(last_touch_time),
      cached_action_(cached_action),
      cached_action_index_(cached_action_index),
      flags_(flags) {
  DCHECK(pointer_count_);
  for (size_t i = 0; i < pointer_count; ++i)
    active_touches_[i] = active_touches[i];
}

MotionEventImpl::~MotionEventImpl() {}

MotionEventImpl::PointData MotionEventImpl::GetPointDataFromTouchEvent(
    const TouchEvent& touch) {
  PointData point_data;
  point_data.x = touch.x();
  point_data.y = touch.y();
  point_data.raw_x = touch.root_location_f().x();
  point_data.raw_y = touch.root_location_f().y();
  point_data.touch_id = touch.touch_id();
  point_data.pressure = touch.force();
  point_data.source_device_id = touch.source_device_id();

  float radius_x = touch.radius_x();
  float radius_y = touch.radius_y();
  float rotation_angle_rad = touch.rotation_angle() * M_PI / 180.f;
  DCHECK_GE(radius_x, 0) << "Unexpected x-radius < 0";
  DCHECK_GE(radius_y, 0) << "Unexpected y-radius < 0";
  DCHECK(0 <= rotation_angle_rad && rotation_angle_rad <= M_PI_2)
      << "Unexpected touch rotation angle";

  if (radius_x > radius_y) {
    // The case radius_x == radius_y is omitted from here on purpose: for
    // circles, we want to pass the angle (which could be any value in such
    // cases but always seem to be set to zero) unchanged.
    point_data.touch_major = 2.f * radius_x;
    point_data.touch_minor = 2.f * radius_y;
    point_data.orientation = rotation_angle_rad - M_PI_2;
  } else {
    point_data.touch_major = 2.f * radius_y;
    point_data.touch_minor = 2.f * radius_x;
    point_data.orientation = rotation_angle_rad;
  }

  if (!point_data.touch_major) {
    point_data.touch_major = 2.f * GestureConfiguration::default_radius();
    point_data.touch_minor = 2.f * GestureConfiguration::default_radius();
    point_data.orientation = 0;
  }

  return point_data;
}

void MotionEventImpl::OnTouch(const TouchEvent& touch) {
  switch (touch.type()) {
    case ET_TOUCH_PRESSED:
      AddTouch(touch);
      break;
    case ET_TOUCH_RELEASED:
    case ET_TOUCH_CANCELLED:
      // Removing these touch points needs to be postponed until after the
      // MotionEvent has been dispatched. This cleanup occurs in
      // CleanupRemovedTouchPoints.
      UpdateTouch(touch);
      break;
    case ET_TOUCH_MOVED:
      UpdateTouch(touch);
      break;
    default:
      NOTREACHED();
      break;
  }

  UpdateCachedAction(touch);
  flags_ = touch.flags();
  last_touch_time_ = touch.time_stamp() + base::TimeTicks();
}

int MotionEventImpl::GetId() const {
  return GetPointerId(0);
}

MotionEvent::Action MotionEventImpl::GetAction() const {
  return cached_action_;
}

int MotionEventImpl::GetActionIndex() const {
  DCHECK(cached_action_ == ACTION_POINTER_DOWN ||
         cached_action_ == ACTION_POINTER_UP);
  DCHECK_GE(cached_action_index_, 0);
  DCHECK_LT(cached_action_index_, static_cast<int>(pointer_count_));
  return cached_action_index_;
}

size_t MotionEventImpl::GetPointerCount() const { return pointer_count_; }

int MotionEventImpl::GetPointerId(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].touch_id;
}

float MotionEventImpl::GetX(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].x;
}

float MotionEventImpl::GetY(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].y;
}

float MotionEventImpl::GetRawX(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].raw_x;
}

float MotionEventImpl::GetRawY(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].raw_y;
}

float MotionEventImpl::GetTouchMajor(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].touch_major;
}

float MotionEventImpl::GetTouchMinor(size_t pointer_index) const {
  DCHECK_LE(pointer_index, pointer_count_);
  return active_touches_[pointer_index].touch_minor;
}

float MotionEventImpl::GetOrientation(size_t pointer_index) const {
  DCHECK_LE(pointer_index, pointer_count_);
  return active_touches_[pointer_index].orientation;
}

float MotionEventImpl::GetPressure(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].pressure;
}

MotionEvent::ToolType MotionEventImpl::GetToolType(size_t pointer_index) const {
  // TODO(jdduke): Plumb tool type from the platform, crbug.com/404128.
  DCHECK_LT(pointer_index, pointer_count_);
  return MotionEvent::TOOL_TYPE_UNKNOWN;
}

int MotionEventImpl::GetButtonState() const {
  NOTIMPLEMENTED();
  return 0;
}

int MotionEventImpl::GetFlags() const {
  return flags_;
}

base::TimeTicks MotionEventImpl::GetEventTime() const {
  return last_touch_time_;
}

scoped_ptr<MotionEvent> MotionEventImpl::Clone() const {
  return scoped_ptr<MotionEvent>(new MotionEventImpl(pointer_count_,
                                                     last_touch_time_,
                                                     cached_action_,
                                                     cached_action_index_,
                                                     flags_,
                                                     active_touches_));
}
scoped_ptr<MotionEvent> MotionEventImpl::Cancel() const {
  return scoped_ptr<MotionEvent>(new MotionEventImpl(
      pointer_count_, last_touch_time_, ACTION_CANCEL, -1, 0, active_touches_));
}

void MotionEventImpl::CleanupRemovedTouchPoints(const TouchEvent& event) {
  if (event.type() != ET_TOUCH_RELEASED &&
      event.type() != ET_TOUCH_CANCELLED) {
    return;
  }

  int index_to_delete = static_cast<int>(GetIndexFromId(event.touch_id()));
  pointer_count_--;
  active_touches_[index_to_delete] = active_touches_[pointer_count_];
}

MotionEventImpl::PointData::PointData()
    : x(0),
      y(0),
      raw_x(0),
      raw_y(0),
      touch_id(0),
      pressure(0),
      source_device_id(0),
      touch_major(0),
      touch_minor(0),
      orientation(0) {
}

int MotionEventImpl::GetSourceDeviceId(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointer_count_);
  return active_touches_[pointer_index].source_device_id;
}

void MotionEventImpl::AddTouch(const TouchEvent& touch) {
  if (pointer_count_ == MotionEvent::MAX_TOUCH_POINT_COUNT)
    return;

  active_touches_[pointer_count_] = GetPointDataFromTouchEvent(touch);
  pointer_count_++;
}


void MotionEventImpl::UpdateTouch(const TouchEvent& touch) {
  active_touches_[GetIndexFromId(touch.touch_id())] =
      GetPointDataFromTouchEvent(touch);
}

void MotionEventImpl::UpdateCachedAction(const TouchEvent& touch) {
  DCHECK(pointer_count_);
  switch (touch.type()) {
    case ET_TOUCH_PRESSED:
      if (pointer_count_ == 1) {
        cached_action_ = ACTION_DOWN;
      } else {
        cached_action_ = ACTION_POINTER_DOWN;
        cached_action_index_ =
            static_cast<int>(GetIndexFromId(touch.touch_id()));
      }
      break;
    case ET_TOUCH_RELEASED:
      if (pointer_count_ == 1) {
        cached_action_ = ACTION_UP;
      } else {
        cached_action_ = ACTION_POINTER_UP;
        cached_action_index_ =
            static_cast<int>(GetIndexFromId(touch.touch_id()));
        DCHECK_LT(cached_action_index_, static_cast<int>(pointer_count_));
      }
      break;
    case ET_TOUCH_CANCELLED:
      cached_action_ = ACTION_CANCEL;
      break;
    case ET_TOUCH_MOVED:
      cached_action_ = ACTION_MOVE;
      break;
    default:
      NOTREACHED();
      break;
  }
}

size_t MotionEventImpl::GetIndexFromId(int id) const {
  for (size_t i = 0; i < pointer_count_; ++i) {
    if (active_touches_[i].touch_id == id)
      return i;
  }
  NOTREACHED();
  return 0;
}

}  // namespace ui
