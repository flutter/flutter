// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter_fallback.h"

#include "flutter/fml/logging.h"

namespace shell {
namespace {

fml::TimePoint SnapToNextTick(fml::TimePoint value,
                              fml::TimePoint tick_phase,
                              fml::TimeDelta tick_interval) {
  fml::TimeDelta offset = (tick_phase - value) % tick_interval;
  if (offset != fml::TimeDelta::Zero())
    offset = offset + tick_interval;
  return value + offset;
}

}  // namespace

VsyncWaiterFallback::VsyncWaiterFallback(blink::TaskRunners task_runners)
    : VsyncWaiter(std::move(task_runners)),
      phase_(fml::TimePoint::Now()),
      weak_factory_(this) {}

VsyncWaiterFallback::~VsyncWaiterFallback() = default;

constexpr fml::TimeDelta interval = fml::TimeDelta::FromSecondsF(1.0 / 60.0);

// |shell::VsyncWaiter|
void VsyncWaiterFallback::AwaitVSync() {
  fml::TimePoint now = fml::TimePoint::Now();
  fml::TimePoint next = SnapToNextTick(now, phase_, interval);

  task_runners_.GetUITaskRunner()->PostDelayedTask(
      [self = weak_factory_.GetWeakPtr()] {
        if (self) {
          const auto frame_time = fml::TimePoint::Now();
          self->FireCallback(frame_time, frame_time + interval);
        }
      },
      next - now);
}

}  // namespace shell
