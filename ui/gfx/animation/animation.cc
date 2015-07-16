// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/animation/animation.h"

#include "ui/gfx/animation/animation_container.h"
#include "ui/gfx/animation/animation_delegate.h"
#include "ui/gfx/animation/tween.h"
#include "ui/gfx/rect.h"

namespace gfx {

Animation::Animation(base::TimeDelta timer_interval)
    : timer_interval_(timer_interval),
      is_animating_(false),
      delegate_(NULL) {
}

Animation::~Animation() {
  // Don't send out notification from the destructor. Chances are the delegate
  // owns us and is being deleted as well.
  if (is_animating_)
    container_->Stop(this);
}

void Animation::Start() {
  if (is_animating_)
    return;

  if (!container_.get())
    container_ = new AnimationContainer();

  is_animating_ = true;

  container_->Start(this);

  AnimationStarted();
}

void Animation::Stop() {
  if (!is_animating_)
    return;

  is_animating_ = false;

  // Notify the container first as the delegate may delete us.
  container_->Stop(this);

  AnimationStopped();

  if (delegate_) {
    if (ShouldSendCanceledFromStop())
      delegate_->AnimationCanceled(this);
    else
      delegate_->AnimationEnded(this);
  }
}

double Animation::CurrentValueBetween(double start, double target) const {
  return Tween::DoubleValueBetween(GetCurrentValue(), start, target);
}

int Animation::CurrentValueBetween(int start, int target) const {
  return Tween::IntValueBetween(GetCurrentValue(), start, target);
}

gfx::Rect Animation::CurrentValueBetween(const gfx::Rect& start_bounds,
                                         const gfx::Rect& target_bounds) const {
  return Tween::RectValueBetween(
      GetCurrentValue(), start_bounds, target_bounds);
}

void Animation::SetContainer(AnimationContainer* container) {
  if (container == container_.get())
    return;

  if (is_animating_)
    container_->Stop(this);

  if (container)
    container_ = container;
  else
    container_ = new AnimationContainer();

  if (is_animating_)
    container_->Start(this);
}

// static
bool Animation::ShouldRenderRichAnimation() {
  return true;
}

bool Animation::ShouldSendCanceledFromStop() {
  return false;
}

void Animation::SetStartTime(base::TimeTicks start_time) {
  start_time_ = start_time;
}

base::TimeDelta Animation::GetTimerInterval() const {
  return timer_interval_;
}

}  // namespace gfx
