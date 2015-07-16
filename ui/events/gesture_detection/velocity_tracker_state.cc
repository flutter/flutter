// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/velocity_tracker_state.h"

#include "base/logging.h"
#include "ui/events/gesture_detection/motion_event.h"

namespace ui {
namespace {
// Special constant to request the velocity of the active pointer.
const int ACTIVE_POINTER_ID = -1;
}

VelocityTrackerState::VelocityTrackerState()
    : velocity_tracker_(VelocityTracker::STRATEGY_DEFAULT),
      active_pointer_id_(ACTIVE_POINTER_ID) {}

VelocityTrackerState::VelocityTrackerState(VelocityTracker::Strategy strategy)
    : velocity_tracker_(strategy), active_pointer_id_(ACTIVE_POINTER_ID) {}

VelocityTrackerState::~VelocityTrackerState() {}

void VelocityTrackerState::Clear() {
  velocity_tracker_.Clear();
  active_pointer_id_ = ACTIVE_POINTER_ID;
  calculated_id_bits_.clear();
}

void VelocityTrackerState::AddMovement(const MotionEvent& event) {
  velocity_tracker_.AddMovement(event);
}

void VelocityTrackerState::ComputeCurrentVelocity(int32_t units,
                                                  float max_velocity) {
  DCHECK_GE(max_velocity, 0);

  BitSet32 id_bits(velocity_tracker_.GetCurrentPointerIdBits());
  calculated_id_bits_ = id_bits;

  for (uint32_t index = 0; !id_bits.is_empty(); index++) {
    uint32_t id = id_bits.clear_first_marked_bit();

    float vx, vy;
    velocity_tracker_.GetVelocity(id, &vx, &vy);

    vx = vx * units / 1000.f;
    vy = vy * units / 1000.f;

    if (vx > max_velocity)
      vx = max_velocity;
    else if (vx < -max_velocity)
      vx = -max_velocity;

    if (vy > max_velocity)
      vy = max_velocity;
    else if (vy < -max_velocity)
      vy = -max_velocity;

    Velocity& velocity = calculated_velocity_[index];
    velocity.vx = vx;
    velocity.vy = vy;
  }
}

float VelocityTrackerState::GetXVelocity(int32_t id) const {
  float vx;
  GetVelocity(id, &vx, NULL);
  return vx;
}

float VelocityTrackerState::GetYVelocity(int32_t id) const {
  float vy;
  GetVelocity(id, NULL, &vy);
  return vy;
}

void VelocityTrackerState::GetVelocity(int32_t id,
                                       float* out_vx,
                                       float* out_vy) const {
  DCHECK(out_vx || out_vy);
  if (id == ACTIVE_POINTER_ID)
    id = velocity_tracker_.GetActivePointerId();

  float vx, vy;
  if (id >= 0 && id <= MotionEvent::MAX_POINTER_ID &&
      calculated_id_bits_.has_bit(id)) {
    uint32_t index = calculated_id_bits_.get_index_of_bit(id);
    const Velocity& velocity = calculated_velocity_[index];
    vx = velocity.vx;
    vy = velocity.vy;
  } else {
    vx = 0;
    vy = 0;
  }

  if (out_vx)
    *out_vx = vx;

  if (out_vy)
    *out_vy = vy;
}

}  // namespace ui
