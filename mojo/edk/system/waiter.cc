// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/waiter.h"

#include "base/logging.h"
#include "mojo/edk/platform/time_ticks.h"

using mojo::platform::GetTimeTicks;
using mojo::util::MutexLocker;

namespace mojo {
namespace system {

Waiter::Waiter()
    :
#ifndef NDEBUG
      initialized_(false),
#endif
      awoken_(false),
      awake_reason_(AwakeReason::CANCELLED),
      awake_context_(static_cast<uint64_t>(-1)) {
}

Waiter::~Waiter() {}

void Waiter::Init() {
#ifndef NDEBUG
  initialized_ = true;
#endif
  awoken_ = false;
}

// TODO(vtl): Fast-path the |deadline == 0| case?
MojoResult Waiter::Wait(MojoDeadline deadline,
                        uint64_t* context,
                        HandleSignalsState* signals_state) {
  MutexLocker locker(&mutex_);

#ifndef NDEBUG
  DCHECK(initialized_);
  // It'll need to be re-initialized after this.
  initialized_ = false;
#endif

  // Fast-path the already-awoken case:
  if (awoken_) {
    if (context)
      *context = awake_context_;
    if (signals_state)
      *signals_state = signals_state_;
    return MojoResultForAwakeReason(awake_reason_);
  }

  if (deadline == MOJO_DEADLINE_INDEFINITE) {
    do {
      cv_.Wait(&mutex_);
    } while (!awoken_);
  } else {
    // We may get spurious wakeups, so record the start time and track the
    // remaining timeout.
    uint64_t wait_remaining = deadline;
    MojoTimeTicks start = GetTimeTicks();
    while (true) {
      // NOTE(vtl): Possibly, we should add a version of |WaitWithTimeout()|
      // that takes an absolute deadline, since that's what pthreads takes.
      if (cv_.WaitWithTimeout(&mutex_, wait_remaining))
        return MOJO_RESULT_DEADLINE_EXCEEDED;  // Definitely timed out.

      // Otherwise, we may have been awoken.
      if (awoken_)
        break;

      // Or the wakeup may have been spurious.
      MojoTimeTicks now = GetTimeTicks();
      DCHECK_GE(now, start);
      uint64_t elapsed = static_cast<uint64_t>(now - start);
      // It's possible that the deadline has passed anyway.
      if (elapsed >= deadline)
        return MOJO_RESULT_DEADLINE_EXCEEDED;

      // Otherwise, recalculate the amount that we have left to wait.
      wait_remaining = deadline - elapsed;
    }
  }

  if (context)
    *context = awake_context_;
  if (signals_state)
    *signals_state = signals_state_;
  return MojoResultForAwakeReason(awake_reason_);
}

void Waiter::Awake(uint64_t context,
                   AwakeReason reason,
                   const HandleSignalsState& signals_state) {
  MutexLocker locker(&mutex_);

  if (awoken_)
    return;

  awoken_ = true;
  awake_reason_ = reason;
  signals_state_ = signals_state;
  awake_context_ = context;
  cv_.Signal();
  // |cv_.Wait()|/|cv_.WaitWithTimeout()| will return after |mutex_| is
  // released.
}

}  // namespace system
}  // namespace mojo
