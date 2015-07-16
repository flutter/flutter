// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/motion_event_generic.h"

#include "base/logging.h"

namespace ui {

PointerProperties::PointerProperties()
    : id(0),
      tool_type(MotionEvent::TOOL_TYPE_UNKNOWN),
      x(0),
      y(0),
      raw_x(0),
      raw_y(0),
      pressure(0),
      touch_major(0),
      touch_minor(0),
      orientation(0) {
}

PointerProperties::PointerProperties(float x, float y)
    : id(0),
      tool_type(MotionEvent::TOOL_TYPE_UNKNOWN),
      x(x),
      y(y),
      raw_x(x),
      raw_y(y),
      pressure(0),
      touch_major(0),
      touch_minor(0),
      orientation(0) {
}

MotionEventGeneric::MotionEventGeneric()
    : action_(ACTION_CANCEL),
      id_(0),
      action_index_(0),
      button_state_(0),
      flags_(0) {
}

MotionEventGeneric::MotionEventGeneric(Action action,
                                       base::TimeTicks event_time,
                                       const PointerProperties& pointer)
    : action_(action),
      event_time_(event_time),
      id_(0),
      action_index_(0),
      button_state_(0),
      flags_(0) {
  PushPointer(pointer);
}

MotionEventGeneric::MotionEventGeneric(const MotionEventGeneric& other)
    : action_(other.action_),
      event_time_(other.event_time_),
      id_(other.id_),
      action_index_(other.action_index_),
      button_state_(other.button_state_),
      flags_(other.flags_),
      pointers_(other.pointers_) {
}

MotionEventGeneric::~MotionEventGeneric() {
}

int MotionEventGeneric::GetId() const {
  return id_;
}

MotionEvent::Action MotionEventGeneric::GetAction() const {
  return action_;
}

int MotionEventGeneric::GetActionIndex() const {
  return action_index_;
}

size_t MotionEventGeneric::GetPointerCount() const {
  return pointers_->size();
}

int MotionEventGeneric::GetPointerId(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].id;
}

float MotionEventGeneric::GetX(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].x;
}

float MotionEventGeneric::GetY(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].y;
}

float MotionEventGeneric::GetRawX(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].raw_x;
}

float MotionEventGeneric::GetRawY(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].raw_y;
}

float MotionEventGeneric::GetTouchMajor(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].touch_major;
}

float MotionEventGeneric::GetTouchMinor(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].touch_minor;
}

float MotionEventGeneric::GetOrientation(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].orientation;
}

float MotionEventGeneric::GetPressure(size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].pressure;
}

MotionEvent::ToolType MotionEventGeneric::GetToolType(
    size_t pointer_index) const {
  DCHECK_LT(pointer_index, pointers_->size());
  return pointers_[pointer_index].tool_type;
}

int MotionEventGeneric::GetButtonState() const {
  return button_state_;
}

int MotionEventGeneric::GetFlags() const {
  return flags_;
}

base::TimeTicks MotionEventGeneric::GetEventTime() const {
  return event_time_;
}

scoped_ptr<MotionEvent> MotionEventGeneric::Clone() const {
  return scoped_ptr<MotionEvent>(new MotionEventGeneric(*this));
}

scoped_ptr<MotionEvent> MotionEventGeneric::Cancel() const {
  scoped_ptr<MotionEventGeneric> event(new MotionEventGeneric(*this));
  event->set_action(ACTION_CANCEL);
  return event.Pass();
}

void MotionEventGeneric::PushPointer(const PointerProperties& pointer) {
  pointers_->push_back(pointer);
}

void MotionEventGeneric::PopPointer() {
  DCHECK_GT(pointers_->size(), 0U);
  pointers_->pop_back();
}

}  // namespace ui
