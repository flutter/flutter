// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/sleep.h"

#include <errno.h>
#include <stdint.h>
#include <time.h>

#include <limits>

#include "base/logging.h"
#include "mojo/edk/system/test/timeouts.h"

namespace mojo {
namespace system {
namespace test {

void Sleep(MojoDeadline duration) {
  // TODO(vtl): This doesn't handle |MOJO_DEADLINE_INDEFINITE|. Should it?
  DCHECK_NE(duration, MOJO_DEADLINE_INDEFINITE);

  const uint64_t kMicrosecondsPerSecond = 1000000ULL;
  const uint64_t kNanosecondsPerMicrosecond = 1000ULL;

  uint64_t sleep_time_seconds = duration / kMicrosecondsPerSecond;
  // |sleep_time.tv_sec| is a |time_t|.
  DCHECK_LE(sleep_time_seconds,
            static_cast<uint64_t>(std::numeric_limits<time_t>::max()));
  uint64_t sleep_time_nanoseconds =
      (duration % kMicrosecondsPerSecond) * kNanosecondsPerMicrosecond;

  struct timespec sleep_time;
  sleep_time.tv_sec = static_cast<time_t>(sleep_time_seconds);
  sleep_time.tv_nsec = static_cast<long>(sleep_time_nanoseconds);

  struct timespec sleep_time_remaining;
  while (nanosleep(&sleep_time, &sleep_time_remaining) == -1) {
    PCHECK(errno == EINTR) << "nanosleep";
    sleep_time = sleep_time_remaining;
  }
}

void SleepMilliseconds(unsigned duration_milliseconds) {
  Sleep(DeadlineFromMilliseconds(duration_milliseconds));
}

}  // namespace test
}  // namespace system
}  // namespace mojo
