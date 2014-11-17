// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/scheduler/timer.h"

#include <cstdlib>

#include "base/bind.h"
#include "base/tracked_objects.h"

namespace sky {

// We're willing to slop around 1/4 of a tick duration to avoid trashing our
// client with irregular ticks.
static const int64 kTickSlop = 4;

Timer::Client::~Client() {
}

Timer::Timer(Client* client,
             scoped_refptr<base::SingleThreadTaskRunner> task_runner)
    : client_(client),
      task_runner_(task_runner),
      enabled_(false),
      weak_factory_(this) {
  DCHECK(client_);
}

Timer::~Timer() {
}

void Timer::SetEnabled(bool enabled) {
  enabled_ = enabled;

  if (enabled_ && current_target_.is_null())
    ScheduleNextTick(base::TimeTicks::Now());
}

void Timer::SetInterval(const TimeInterval& interval) {
  interval_ = interval;

  // We don't have a tick scheduled, so there's no need to reschedule it.
  if (current_target_.is_null())
    return;

  base::TimeTicks now = base::TimeTicks::Now();

  base::TimeTicks new_target = NextTickTarget(now);
  base::TimeDelta delta = base::TimeDelta::FromInternalValue(
      std::abs((new_target - current_target_).ToInternalValue()));

  if (delta * kTickSlop < interval_.duration)
    return;

  current_target_ = base::TimeTicks();
  weak_factory_.InvalidateWeakPtrs();
  PostTickTask(now, new_target);
}

base::TimeTicks Timer::NextTickTarget(base::TimeTicks now) {
  base::TimeTicks target = interval_.NextAfter(now);

  // If we're targeting a time that's too soon since the last tick, we push out
  // the target to the next tick.
  if ((target - last_tick_) * kTickSlop < interval_.duration)
    target += interval_.duration;

  return target;
}

void Timer::ScheduleNextTick(base::TimeTicks now) {
  PostTickTask(now, NextTickTarget(now));
}

void Timer::PostTickTask(base::TimeTicks now, base::TimeTicks target) {
  DCHECK(current_target_.is_null());
  current_target_ = target;
  task_runner_->PostDelayedTask(
      FROM_HERE, base::Bind(&Timer::OnTimerFired, weak_factory_.GetWeakPtr()),
      current_target_ - now);
}

void Timer::OnTimerFired() {
  current_target_ = base::TimeTicks();
  if (!enabled_)
    return;
  base::TimeTicks now = base::TimeTicks::Now();
  ScheduleNextTick(now);
  last_tick_ = now;
  client_->OnTimerTick(now);
  // We might be deleted here.
}
}
