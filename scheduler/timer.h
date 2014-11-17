// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SCHEDULER_TIMER_H_
#define SKY_SCHEDULER_TIMER_H_

#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "base/time/time.h"
#include "sky/scheduler/time_interval.h"

namespace sky {

class Timer {
 public:
  class Client {
   public:
    virtual void OnTimerTick(base::TimeTicks now) = 0;

   protected:
    virtual ~Client();
  };

  Timer(Client* client,
        scoped_refptr<base::SingleThreadTaskRunner> task_runner);
  ~Timer();

  void SetInterval(const TimeInterval& parameters);
  void SetEnabled(bool enabled);

 private:
  base::TimeTicks NextTickTarget(base::TimeTicks now);
  void ScheduleNextTick(base::TimeTicks now);
  void PostTickTask(base::TimeTicks now, base::TimeTicks target);
  void OnTimerFired();

  Client* client_;
  scoped_refptr<base::SingleThreadTaskRunner> task_runner_;

  TimeInterval interval_;
  base::TimeTicks last_tick_;
  base::TimeTicks current_target_;

  bool enabled_;

  base::WeakPtrFactory<Timer> weak_factory_;
};

}

#endif  // SKY_SCHEDULER_TIMER_H_
