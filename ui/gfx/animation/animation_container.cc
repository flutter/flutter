// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/animation/animation_container.h"

#include "ui/gfx/animation/animation_container_element.h"
#include "ui/gfx/animation/animation_container_observer.h"
#include "ui/gfx/frame_time.h"

using base::TimeDelta;
using base::TimeTicks;

namespace gfx {

AnimationContainer::AnimationContainer()
    : last_tick_time_(gfx::FrameTime::Now()),
      observer_(NULL) {
}

AnimationContainer::~AnimationContainer() {
  // The animations own us and stop themselves before being deleted. If
  // elements_ is not empty, something is wrong.
  DCHECK(elements_.empty());
}

void AnimationContainer::Start(AnimationContainerElement* element) {
  DCHECK(elements_.count(element) == 0);  // Start should only be invoked if the
                                          // element isn't running.

  if (elements_.empty()) {
    last_tick_time_ = gfx::FrameTime::Now();
    SetMinTimerInterval(element->GetTimerInterval());
  } else if (element->GetTimerInterval() < min_timer_interval_) {
    SetMinTimerInterval(element->GetTimerInterval());
  }

  element->SetStartTime(last_tick_time_);
  elements_.insert(element);
}

void AnimationContainer::Stop(AnimationContainerElement* element) {
  DCHECK(elements_.count(element) > 0);  // The element must be running.

  elements_.erase(element);

  if (elements_.empty()) {
    timer_.Stop();
    if (observer_)
      observer_->AnimationContainerEmpty(this);
  } else {
    TimeDelta min_timer_interval = GetMinInterval();
    if (min_timer_interval > min_timer_interval_)
      SetMinTimerInterval(min_timer_interval);
  }
}

void AnimationContainer::Run() {
  // We notify the observer after updating all the elements. If all the elements
  // are deleted as a result of updating then our ref count would go to zero and
  // we would be deleted before we notify our observer. We add a reference to
  // ourself here to make sure we're still valid after running all the elements.
  scoped_refptr<AnimationContainer> this_ref(this);

  TimeTicks current_time = gfx::FrameTime::Now();

  last_tick_time_ = current_time;

  // Make a copy of the elements to iterate over so that if any elements are
  // removed as part of invoking Step there aren't any problems.
  Elements elements = elements_;

  for (Elements::const_iterator i = elements.begin();
       i != elements.end(); ++i) {
    // Make sure the element is still valid.
    if (elements_.find(*i) != elements_.end())
      (*i)->Step(current_time);
  }

  if (observer_)
    observer_->AnimationContainerProgressed(this);
}

void AnimationContainer::SetMinTimerInterval(base::TimeDelta delta) {
  // This doesn't take into account how far along the current element is, but
  // that shouldn't be a problem for uses of Animation/AnimationContainer.
  timer_.Stop();
  min_timer_interval_ = delta;
  timer_.Start(FROM_HERE, min_timer_interval_, this, &AnimationContainer::Run);
}

TimeDelta AnimationContainer::GetMinInterval() {
  DCHECK(!elements_.empty());

  TimeDelta min;
  Elements::const_iterator i = elements_.begin();
  min = (*i)->GetTimerInterval();
  for (++i; i != elements_.end(); ++i) {
    if ((*i)->GetTimerInterval() < min)
      min = (*i)->GetTimerInterval();
  }
  return min;
}

}  // namespace gfx
