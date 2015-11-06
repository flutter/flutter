// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/waiter.h"

#include "base/logging.h"
#include "base/time/time.h"

using mojo::util::MutexLocker;

namespace mojo {
namespace system {

Waiter::Waiter()
    :
#ifndef NDEBUG
      initialized_(false),
#endif
      awoken_(false),
      awake_result_(MOJO_RESULT_INTERNAL),
      awake_context_(static_cast<uint32_t>(-1)) {
}

Waiter::~Waiter() {
}

void Waiter::Init() {
#ifndef NDEBUG
  initialized_ = true;
#endif
  awoken_ = false;
  // NOTE(vtl): If performance ever becomes an issue, we can disable the setting
  // of |awake_result_| (except the first one in |Awake()|) in Release builds.
  awake_result_ = MOJO_RESULT_INTERNAL;
}

// TODO(vtl): Fast-path the |deadline == 0| case?
MojoResult Waiter::Wait(MojoDeadline deadline, uint32_t* context) {
  MutexLocker locker(&mutex_);

#ifndef NDEBUG
  DCHECK(initialized_);
  // It'll need to be re-initialized after this.
  initialized_ = false;
#endif

  // Fast-path the already-awoken case:
  if (awoken_) {
    DCHECK_NE(awake_result_, MOJO_RESULT_INTERNAL);
    if (context)
      *context = static_cast<uint32_t>(awake_context_);
    return awake_result_;
  }

  if (deadline == MOJO_DEADLINE_INDEFINITE) {
    do {
      cv_.Wait(&mutex_);
    } while (!awoken_);
  } else {
    // We may get spurious wakeups, so record the start time and track the
    // remaining timeout.
    uint64_t wait_remaining = deadline;
    auto start = base::TimeTicks::Now();
    while (true) {
      // NOTE(vtl): Possibly, we should add a version of |WaitWithTimeout()|
      // that takes an absolute deadline, since that's what pthreads takes.
      if (cv_.WaitWithTimeout(&mutex_, wait_remaining))
        return MOJO_RESULT_DEADLINE_EXCEEDED;  // Definitely timed out.

      // Otherwise, we may have been awoken.
      if (awoken_)
        break;

      // Or the wakeup may have been spurious.
      auto now = base::TimeTicks::Now();
      DCHECK_GE(now, start);
      uint64_t elapsed = static_cast<uint64_t>((now - start).InMicroseconds());
      // It's possible that the deadline has passed anyway.
      if (elapsed >= deadline)
        return MOJO_RESULT_DEADLINE_EXCEEDED;

      // Otherwise, recalculate the amount that we have left to wait.
      wait_remaining = deadline - elapsed;
    }
  }

  DCHECK_NE(awake_result_, MOJO_RESULT_INTERNAL);
  if (context)
    *context = static_cast<uint32_t>(awake_context_);
  return awake_result_;
}

bool Waiter::Awake(MojoResult result, uintptr_t context) {
  MutexLocker locker(&mutex_);

  if (awoken_)
    return true;

  awoken_ = true;
  awake_result_ = result;
  awake_context_ = context;
  cv_.Signal();
  // |cv_.Wait()|/|cv_.WaitWithTimeout()| will return after |mutex_| is
  // released.
  return true;
}

}  // namespace system
}  // namespace mojo
