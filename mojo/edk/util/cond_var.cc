// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/cond_var.h"

#include <errno.h>
#include <string.h>
#include <time.h>

#include <limits>

#include "build/build_config.h"
#include "mojo/edk/util/logging_internal.h"
#include "mojo/edk/util/mutex.h"

namespace mojo {
namespace util {

namespace {

// Helper for |CondVar::WaitWithTimeout()|. Returns true on (definite) time-out.
bool RelativeTimedWait(const struct timespec& timeout_rel,
                       pthread_cond_t* posix_cond_var,
                       pthread_mutex_t* posix_mutex) {
// Mac has a function to do a relative timed wait directly.
#if defined(OS_MACOSX)
  int error = pthread_cond_timedwait_relative_np(posix_cond_var, posix_mutex,
                                                 &timeout_rel);
  INTERNAL_DCHECK_WITH_ERRNO(error == 0 || error == ETIMEDOUT || error == EINTR,
                             "pthread_cond_timedwait_relative_np", error);
  return error == ETIMEDOUT;
#else
  static const long kNanosecondsPerSecond = 1000000000L;

// NaCl's |pthread_condattr_setclock()| only supports |CLOCK_REALTIME| (which is
// the default, which is why we don't bother setting it in |CondVar|'s
// constructor).
#if defined(OS_NACL)
  static const clockid_t kClockType = CLOCK_REALTIME;
#else
  static const clockid_t kClockType = CLOCK_MONOTONIC;
#endif  // defined(OS_NACL)

  struct timespec timeout_abs;
  int error = clock_gettime(kClockType, &timeout_abs);
  // Note: The return value of |clock_gettime()| is *not* an error code, unlike
  // the pthreads functions (however, it sets errno).
  INTERNAL_DCHECK_WITH_ERRNO(!error, "clock_gettime", errno);

  timeout_abs.tv_sec += timeout_rel.tv_sec;
  timeout_abs.tv_nsec += timeout_rel.tv_nsec;
  if (timeout_abs.tv_nsec >= kNanosecondsPerSecond) {
    timeout_abs.tv_sec++;
    timeout_abs.tv_nsec -= kNanosecondsPerSecond;
    INTERNAL_DCHECK(timeout_abs.tv_nsec < kNanosecondsPerSecond);
  }

// Older Android doesn't have |pthread_condattr_setclock()|, but they have
// |pthread_cond_timedwait_monotonic_np()|.
#if defined(OS_ANDROID) && defined(HAVE_PTHREAD_COND_TIMEDWAIT_MONOTONIC)
  error = pthread_cond_timedwait_monotonic_np(posix_cond_var, posix_mutex,
                                              &timeout_abs);
  INTERNAL_DCHECK_WITH_ERRNO(error == 0 || error == ETIMEDOUT || error == EINTR,
                             "pthread_cond_timedwait_monotonic_np", error);
#else
  error = pthread_cond_timedwait(posix_cond_var, posix_mutex, &timeout_abs);
  INTERNAL_DCHECK_WITH_ERRNO(error == 0 || error == ETIMEDOUT || error == EINTR,
                             "pthread_cond_timedwait", error);
#endif  // defined(OS_ANDROID) && defined(HAVE_PTHREAD_COND_TIMEDWAIT_MONOTONIC)
  return error == ETIMEDOUT;
#endif  // defined(OS_MACOSX)
}

}  // namespace

CondVar::CondVar() {
// Mac and older Android don't have |pthread_condattr_setclock()| (but they have
// other timed wait functions we can use) and NaCl doesn't have a useful one.
#if !defined(OS_MACOSX) && !defined(OS_NACL) && \
    !(defined(OS_ANDROID) && defined(HAVE_PTHREAD_COND_TIMEDWAIT_MONOTONIC))
  pthread_condattr_t attr;
  int error = pthread_condattr_init(&attr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_condattr_init", error);
  error = pthread_condattr_setclock(&attr, CLOCK_MONOTONIC);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_condattr_setclock", error);
  error = pthread_cond_init(&impl_, &attr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_cond_init", error);
  error = pthread_condattr_destroy(&attr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_condattr_destroy", error);
#else
  int error = pthread_cond_init(&impl_, nullptr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_cond_init", error);
#endif  // !defined(OS_MACOSX) && !defined(OS_NACL) && !(defined(OS_ANDROID)...)
}

CondVar::~CondVar() {
  int error = pthread_cond_destroy(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_cond_destroy", error);
}

void CondVar::Wait(Mutex* mutex) {
  INTERNAL_DCHECK(mutex);
  mutex->AssertHeld();

  int error = pthread_cond_wait(&impl_, &mutex->impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_cond_wait", error);
}

bool CondVar::WaitWithTimeout(Mutex* mutex, uint64_t timeout_microseconds) {
  static const uint64_t kMicrosecondsPerSecond = 1000000ULL;
  static const uint64_t kNanosecondsPerMicrosecond = 1000ULL;

  // Turn very long waits into "forever". This isn't a huge concern if |time_t|
  // is 64-bit, but overflowing |time_t| is a real risk if it's only 32-bit.
  // (2^31 / 16 seconds = ~4.25 years, so we won't risk overflowing until 2033.)
  constexpr uint64_t kForeverThresholdSeconds =
      std::numeric_limits<time_t>::max() / 16;
  uint64_t timeout_seconds = timeout_microseconds / kMicrosecondsPerSecond;
  if (timeout_seconds >= kForeverThresholdSeconds) {
    Wait(mutex);
    return false;  // Did *not* time out.
  }

  INTERNAL_DCHECK(mutex);
  mutex->AssertHeld();

  struct timespec timeout_rel = {};
  timeout_rel.tv_sec = static_cast<time_t>(timeout_seconds);
  timeout_rel.tv_nsec =
      static_cast<long>((timeout_microseconds % kMicrosecondsPerSecond) *
                        kNanosecondsPerMicrosecond);
  return RelativeTimedWait(timeout_rel, &impl_, &mutex->impl_);
}

void CondVar::Signal() {
  int error = pthread_cond_signal(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_cond_signal", error);
}

void CondVar::SignalAll() {
  int error = pthread_cond_broadcast(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_cond_broadcast", error);
}

}  // namespace util
}  // namespace mojo
