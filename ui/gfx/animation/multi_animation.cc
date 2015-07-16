// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/animation/multi_animation.h"

#include "base/logging.h"
#include "ui/gfx/animation/animation_delegate.h"

namespace gfx {

// Default interval, in ms.
static const int kDefaultTimerInterval = 20;

static int TotalTime(const MultiAnimation::Parts& parts) {
  int time_ms = 0;
  for (size_t i = 0; i < parts.size(); ++i) {
    DCHECK(parts[i].end_time_ms - parts[i].start_time_ms >= parts[i].time_ms);
    time_ms += parts[i].time_ms;
  }
  return time_ms;
}

MultiAnimation::MultiAnimation(const Parts& parts,
                               base::TimeDelta timer_interval)
    : Animation(timer_interval),
      parts_(parts),
      cycle_time_ms_(TotalTime(parts)),
      current_value_(0),
      current_part_index_(0),
      continuous_(true) {
  DCHECK(!parts_.empty());
}

MultiAnimation::~MultiAnimation() {}

// static.
base::TimeDelta MultiAnimation::GetDefaultTimerInterval() {
  return base::TimeDelta::FromMilliseconds(kDefaultTimerInterval);
}

double MultiAnimation::GetCurrentValue() const {
  return current_value_;
}

void MultiAnimation::Step(base::TimeTicks time_now) {
  double last_value = current_value_;
  size_t last_index = current_part_index_;

  int delta = static_cast<int>((time_now - start_time()).InMilliseconds());
  if (delta >= cycle_time_ms_ && !continuous_) {
    current_part_index_ = parts_.size() - 1;
    current_value_ = Tween::CalculateValue(parts_[current_part_index_].type, 1);
    Stop();
    return;
  }
  delta %= cycle_time_ms_;
  const Part& part = GetPart(&delta, &current_part_index_);
  double percent = static_cast<double>(delta + part.start_time_ms) /
        static_cast<double>(part.end_time_ms);
  DCHECK(percent <= 1);
  current_value_ = Tween::CalculateValue(part.type, percent);

  if ((current_value_ != last_value || current_part_index_ != last_index) &&
      delegate()) {
    delegate()->AnimationProgressed(this);
  }
}

void MultiAnimation::SetStartTime(base::TimeTicks start_time) {
  Animation::SetStartTime(start_time);
  current_value_ = 0;
  current_part_index_ = 0;
}

const MultiAnimation::Part& MultiAnimation::GetPart(int* time_ms,
                                                    size_t* part_index) {
  DCHECK(*time_ms < cycle_time_ms_);

  for (size_t i = 0; i < parts_.size(); ++i) {
    if (*time_ms < parts_[i].time_ms) {
      *part_index = i;
      return parts_[i];
    }

    *time_ms -= parts_[i].time_ms;
  }
  NOTREACHED();
  *time_ms = 0;
  *part_index = 0;
  return parts_[0];
}

}  // namespace gfx
