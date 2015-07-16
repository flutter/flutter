// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/snap_scroll_controller.h"

#include <cmath>

#include "ui/events/gesture_detection/motion_event.h"
#include "ui/gfx/display.h"

namespace ui {
namespace {
const int kSnapBound = 16;
const float kMinSnapChannelDistance = kSnapBound;
const float kMaxSnapChannelDistance = kMinSnapChannelDistance * 3.f;
const float kSnapChannelDipsPerScreenDip = kMinSnapChannelDistance / 480.f;

float CalculateChannelDistance(const gfx::Display& display) {
  if (display.bounds().IsEmpty())
    return kMinSnapChannelDistance;

  float screen_size =
      std::abs(hypot(static_cast<float>(display.bounds().width()),
                     static_cast<float>(display.bounds().height())));

  float snap_channel_distance = screen_size * kSnapChannelDipsPerScreenDip;
  return std::max(kMinSnapChannelDistance,
                  std::min(kMaxSnapChannelDistance, snap_channel_distance));
}

}  // namespace


SnapScrollController::SnapScrollController(const gfx::Display& display)
    : channel_distance_(CalculateChannelDistance(display)),
      snap_scroll_mode_(SNAP_NONE),
      first_touch_x_(-1),
      first_touch_y_(-1),
      distance_x_(0),
      distance_y_(0) {}

SnapScrollController::~SnapScrollController() {}

void SnapScrollController::UpdateSnapScrollMode(float distance_x,
                                                float distance_y) {
  if (snap_scroll_mode_ == SNAP_HORIZ || snap_scroll_mode_ == SNAP_VERT) {
    distance_x_ += std::abs(distance_x);
    distance_y_ += std::abs(distance_y);
    if (snap_scroll_mode_ == SNAP_HORIZ) {
      if (distance_y_ > channel_distance_) {
        snap_scroll_mode_ = SNAP_NONE;
      } else if (distance_x_ > channel_distance_) {
        distance_x_ = 0;
        distance_y_ = 0;
      }
    } else {
      if (distance_x_ > channel_distance_) {
        snap_scroll_mode_ = SNAP_NONE;
      } else if (distance_y_ > channel_distance_) {
        distance_x_ = 0;
        distance_y_ = 0;
      }
    }
  }
}

void SnapScrollController::SetSnapScrollingMode(
    const MotionEvent& event,
    bool is_scale_gesture_detection_in_progress) {
  switch (event.GetAction()) {
    case MotionEvent::ACTION_DOWN:
      snap_scroll_mode_ = SNAP_NONE;
      first_touch_x_ = event.GetX();
      first_touch_y_ = event.GetY();
      break;
    // Set scrolling mode to SNAP_X if scroll towards x-axis exceeds kSnapBound
    // and movement towards y-axis is trivial.
    // Set scrolling mode to SNAP_Y if scroll towards y-axis exceeds kSnapBound
    // and movement towards x-axis is trivial.
    // Scrolling mode will remain in SNAP_NONE for other conditions.
    case MotionEvent::ACTION_MOVE:
      if (!is_scale_gesture_detection_in_progress &&
          snap_scroll_mode_ == SNAP_NONE) {
        int x_diff = static_cast<int>(std::abs(event.GetX() - first_touch_x_));
        int y_diff = static_cast<int>(std::abs(event.GetY() - first_touch_y_));
        if (x_diff > kSnapBound && y_diff < kSnapBound) {
          snap_scroll_mode_ = SNAP_HORIZ;
        } else if (x_diff < kSnapBound && y_diff > kSnapBound) {
          snap_scroll_mode_ = SNAP_VERT;
        }
      }
      break;
    case MotionEvent::ACTION_UP:
    case MotionEvent::ACTION_CANCEL:
      first_touch_x_ = -1;
      first_touch_y_ = -1;
      distance_x_ = 0;
      distance_y_ = 0;
      break;
    default:
      break;
  }
}

}  // namespace ui
