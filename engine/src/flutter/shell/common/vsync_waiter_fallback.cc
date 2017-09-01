// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/vsync_waiter_fallback.h"

#include "lib/ftl/logging.h"
#include "flutter/common/threads.h"

namespace shell {
namespace {

ftl::TimePoint SnapToNextTick(ftl::TimePoint value,
                              ftl::TimePoint tick_phase,
                              ftl::TimeDelta tick_interval) {
  ftl::TimeDelta offset = (tick_phase - value) % tick_interval;
  if (offset != ftl::TimeDelta::Zero())
    offset = offset + tick_interval;
  return value + offset;
}

}  // namespace

VsyncWaiterFallback::VsyncWaiterFallback()
    : phase_(ftl::TimePoint::Now()), weak_factory_(this) {}

VsyncWaiterFallback::~VsyncWaiterFallback() = default;

constexpr ftl::TimeDelta interval = ftl::TimeDelta::FromSecondsF(1.0 / 60.0);

void VsyncWaiterFallback::AsyncWaitForVsync(Callback callback) {
  FTL_DCHECK(!callback_);
  callback_ = std::move(callback);

  ftl::TimePoint now = ftl::TimePoint::Now();
  ftl::TimePoint next = SnapToNextTick(now, phase_, interval);

  blink::Threads::UI()->PostDelayedTask(
      [self = weak_factory_.GetWeakPtr()] {
        if (!self)
          return;
        ftl::TimePoint frame_time = ftl::TimePoint::Now();
        Callback callback = std::move(self->callback_);
        self->callback_ = Callback();
        callback(frame_time, frame_time + interval);
      },
      next - now);
}

}  // namespace shell
