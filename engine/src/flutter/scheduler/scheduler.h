// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SCHEDULER_SCHEDULER_H_
#define SKY_SCHEDULER_SCHEDULER_H_

#include "base/single_thread_task_runner.h"
#include "base/time/time.h"
#include "sky/scheduler/timer.h"

namespace sky {

class Scheduler : public Timer::Client {
 public:
  class Client {
   public:
    virtual void BeginFrame(base::TimeTicks frame_time,
                            base::TimeTicks deadline) = 0;

   protected:
    virtual ~Client();
  };

  Scheduler(Client* client,
            scoped_refptr<base::SingleThreadTaskRunner> task_runner);
  ~Scheduler();

  void UpdateFrameDuration(base::TimeDelta estimate);
  void UpdateVSync(const TimeInterval& vsync);

  void SetNeedsFrame();

 private:
  void UpdateTimerInterval();
  void OnTimerTick(base::TimeTicks now) override;

  Client* client_;
  Timer timer_;
  TimeInterval vsync_;
  base::TimeDelta frame_duration_;
};
}

#endif  // SKY_SCHEDULER_SCHEDULER_H_
