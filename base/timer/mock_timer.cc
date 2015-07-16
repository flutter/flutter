// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/timer/mock_timer.h"

namespace base {

MockTimer::MockTimer(bool retain_user_task, bool is_repeating)
    : Timer(retain_user_task, is_repeating),
      is_running_(false) {
}

MockTimer::MockTimer(const tracked_objects::Location& posted_from,
                     TimeDelta delay,
                     const base::Closure& user_task,
                     bool is_repeating)
    : Timer(true, is_repeating),
      delay_(delay),
      is_running_(false) {
}

MockTimer::~MockTimer() {
}

bool MockTimer::IsRunning() const {
  return is_running_;
}

base::TimeDelta MockTimer::GetCurrentDelay() const {
  return delay_;
}

void MockTimer::Start(const tracked_objects::Location& posted_from,
                      TimeDelta delay,
                      const base::Closure& user_task) {
  delay_ = delay;
  user_task_ = user_task;
  Reset();
}

void MockTimer::Stop() {
  is_running_ = false;
  if (!retain_user_task())
    user_task_.Reset();
}

void MockTimer::Reset() {
  DCHECK(!user_task_.is_null());
  is_running_ = true;
}

void MockTimer::Fire() {
  DCHECK(is_running_);
  base::Closure old_task = user_task_;
  if (is_repeating())
    Reset();
  else
    Stop();
  old_task.Run();
}

}  // namespace base
