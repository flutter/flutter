// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter_fallback.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace {

static fml::TimePoint SnapToNextTick(fml::TimePoint value,
                                     fml::TimePoint tick_phase,
                                     fml::TimeDelta tick_interval) {
  fml::TimeDelta offset = (tick_phase - value) % tick_interval;
  if (offset != fml::TimeDelta::Zero())
    offset = offset + tick_interval;
  return value + offset;
}

}  // namespace

VsyncWaiterFallback::VsyncWaiterFallback(TaskRunners task_runners,
                                         bool for_testing)
    : VsyncWaiter(std::move(task_runners)),
      phase_(fml::TimePoint::Now()),
      for_testing_(for_testing) {}

VsyncWaiterFallback::~VsyncWaiterFallback() = default;

// |VsyncWaiter|
void VsyncWaiterFallback::AwaitVSync() {
  TRACE_EVENT0("flutter", "VSYNC");

  constexpr fml::TimeDelta kSingleFrameInterval =
      fml::TimeDelta::FromSecondsF(1.0 / 60.0);

  auto next =
      SnapToNextTick(fml::TimePoint::Now(), phase_, kSingleFrameInterval);

  FireCallback(next, next + kSingleFrameInterval, !for_testing_);
}

}  // namespace flutter
