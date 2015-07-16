// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/animation/slide_animation.h"

#include <math.h>

namespace gfx {

// How many frames per second to target.
static const int kDefaultFrameRateHz = 60;

// How long animations should take by default.
static const int kDefaultDurationMs = 120;

SlideAnimation::SlideAnimation(AnimationDelegate* target)
    : LinearAnimation(kDefaultFrameRateHz, target),
      target_(target),
      tween_type_(Tween::EASE_OUT),
      showing_(false),
      value_start_(0),
      value_end_(0),
      value_current_(0),
      slide_duration_(kDefaultDurationMs) {
}

SlideAnimation::~SlideAnimation() {
}

void SlideAnimation::Reset() {
  Reset(0);
}

void SlideAnimation::Reset(double value) {
  Stop();
  showing_ = static_cast<bool>(value == 1);
  value_current_ = value;
}

void SlideAnimation::Show() {
  // If we're already showing (or fully shown), we have nothing to do.
  if (showing_)
    return;

  showing_ = true;
  value_start_ = value_current_;
  value_end_ = 1.0;

  // Make sure we actually have something to do.
  if (slide_duration_ == 0) {
    AnimateToState(1.0);  // Skip to the end of the animation.
    return;
  } else if (value_current_ == value_end_)  {
    return;
  }

  // This will also reset the currently-occurring animation.
  SetDuration(static_cast<int>(slide_duration_ * (1 - value_current_)));
  Start();
}

void SlideAnimation::Hide() {
  // If we're already hiding (or hidden), we have nothing to do.
  if (!showing_)
    return;

  showing_ = false;
  value_start_ = value_current_;
  value_end_ = 0.0;

  // Make sure we actually have something to do.
  if (slide_duration_ == 0) {
    AnimateToState(0.0);  // Skip to the end of the animation.
    return;
  } else if (value_current_ == value_end_) {
    return;
  }

  // This will also reset the currently-occurring animation.
  SetDuration(static_cast<int>(slide_duration_ * value_current_));
  Start();
}

void SlideAnimation::SetSlideDuration(int duration) {
  slide_duration_ = duration;
}

double SlideAnimation::GetCurrentValue() const {
  return value_current_;
}

void SlideAnimation::AnimateToState(double state) {
  if (state > 1.0)
    state = 1.0;

  state = Tween::CalculateValue(tween_type_, state);

  value_current_ = value_start_ + (value_end_ - value_start_) * state;

  // Implement snapping.
  if (tween_type_ == Tween::EASE_OUT_SNAP &&
      fabs(value_current_ - value_end_) <= 0.06)
    value_current_ = value_end_;

  // Correct for any overshoot (while state may be capped at 1.0, let's not
  // take any rounding error chances.
  if ((value_end_ >= value_start_ && value_current_ > value_end_) ||
      (value_end_ < value_start_ && value_current_ < value_end_)) {
    value_current_ = value_end_;
  }
}

}  // namespace gfx
