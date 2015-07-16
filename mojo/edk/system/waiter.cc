// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/waiter.h"

#include <limits>

#include "base/logging.h"
#include "base/time/time.h"

namespace mojo {
namespace system {

Waiter::Waiter()
    : cv_(&lock_),
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
  base::AutoLock locker(lock_);

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

  // |MojoDeadline| is actually a |uint64_t|, but we need a signed quantity.
  // Treat any out-of-range deadline as "forever" (which is wrong, but okay
  // since 2^63 microseconds is ~300000 years). Note that this also takes care
  // of the |MOJO_DEADLINE_INDEFINITE| (= 2^64 - 1) case.
  if (deadline > static_cast<uint64_t>(std::numeric_limits<int64_t>::max())) {
    do {
      cv_.Wait();
    } while (!awoken_);
  } else {
    // NOTE(vtl): This is very inefficient on POSIX, since pthreads condition
    // variables take an absolute deadline.
    const base::TimeTicks end_time =
        base::TimeTicks::Now() +
        base::TimeDelta::FromMicroseconds(static_cast<int64_t>(deadline));
    do {
      base::TimeTicks now_time = base::TimeTicks::Now();
      if (now_time >= end_time)
        return MOJO_RESULT_DEADLINE_EXCEEDED;

      cv_.TimedWait(end_time - now_time);
    } while (!awoken_);
  }

  DCHECK_NE(awake_result_, MOJO_RESULT_INTERNAL);
  if (context)
    *context = static_cast<uint32_t>(awake_context_);
  return awake_result_;
}

bool Waiter::Awake(MojoResult result, uintptr_t context) {
  base::AutoLock locker(lock_);

  if (awoken_)
    return true;

  awoken_ = true;
  awake_result_ = result;
  awake_context_ = context;
  cv_.Signal();
  // |cv_.Wait()|/|cv_.TimedWait()| will return after |lock_| is released.
  return true;
}

}  // namespace system
}  // namespace mojo
