// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TIMER_MOCK_TIMER_H_
#define BASE_TIMER_MOCK_TIMER_H_

#include "base/timer/timer.h"

namespace base {

class BASE_EXPORT MockTimer : public Timer {
 public:
  MockTimer(bool retain_user_task, bool is_repeating);
  MockTimer(const tracked_objects::Location& posted_from,
            TimeDelta delay,
            const base::Closure& user_task,
            bool is_repeating);
  ~MockTimer() override;

  // base::Timer implementation.
  bool IsRunning() const override;
  base::TimeDelta GetCurrentDelay() const override;
  void Start(const tracked_objects::Location& posted_from,
             base::TimeDelta delay,
             const base::Closure& user_task) override;
  void Stop() override;
  void Reset() override;

  // Testing methods.
  void Fire();

 private:
  base::Closure user_task_;
  TimeDelta delay_;
  bool is_running_;
};

}  // namespace base

#endif  // BASE_TIMER_MOCK_TIMER_H_
