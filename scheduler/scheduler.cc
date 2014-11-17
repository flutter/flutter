// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/scheduler/scheduler.h"

namespace sky {

Scheduler::Client::~Client() {
}

Scheduler::Scheduler(Client* client,
                     scoped_refptr<base::SingleThreadTaskRunner> task_runner)
    : client_(client), timer_(this, task_runner) {
}

Scheduler::~Scheduler() {
}

void Scheduler::SetNeedsFrame() {
  timer_.SetEnabled(true);
}

void Scheduler::UpdateFrameDuration(base::TimeDelta estimate) {
  frame_duration_ = estimate;
  UpdateTimerInterval();
}

void Scheduler::UpdateVSync(const TimeInterval& vsync) {
  vsync_ = vsync;
  UpdateTimerInterval();
}

void Scheduler::UpdateTimerInterval() {
  TimeInterval interval = vsync_;
  interval.base -= frame_duration_;
  timer_.SetInterval(interval);
}

void Scheduler::OnTimerTick(base::TimeTicks now) {
  timer_.SetEnabled(false);
  client_->BeginFrame(now, vsync_.NextAfter(now));
  // We might be deleted here.
}
}
