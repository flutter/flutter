// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter_fallback.h"

#include "flutter/common/threads.h"
#include "lib/fxl/logging.h"

namespace shell {
namespace {

fxl::TimePoint SnapToNextTick(fxl::TimePoint value,
                              fxl::TimePoint tick_phase,
                              fxl::TimeDelta tick_interval) {
  fxl::TimeDelta offset = (tick_phase - value) % tick_interval;
  if (offset != fxl::TimeDelta::Zero())
    offset = offset + tick_interval;
  return value + offset;
}

}  // namespace

VsyncWaiterFallback::VsyncWaiterFallback()
    : phase_(fxl::TimePoint::Now()), weak_factory_(this) {}

VsyncWaiterFallback::~VsyncWaiterFallback() = default;

constexpr fxl::TimeDelta interval = fxl::TimeDelta::FromSecondsF(1.0 / 60.0);

void VsyncWaiterFallback::AsyncWaitForVsync(Callback callback) {
  FXL_DCHECK(!callback_);
  callback_ = std::move(callback);

  fxl::TimePoint now = fxl::TimePoint::Now();
  fxl::TimePoint next = SnapToNextTick(now, phase_, interval);

  blink::Threads::UI()->PostDelayedTask(
      [self = weak_factory_.GetWeakPtr()] {
        if (!self)
          return;
        fxl::TimePoint frame_time = fxl::TimePoint::Now();
        Callback callback = std::move(self->callback_);
        self->callback_ = Callback();
        callback(frame_time, frame_time + interval);
      },
      next - now);
}

}  // namespace shell
