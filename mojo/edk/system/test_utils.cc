// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test_utils.h"

#include <stdint.h>
#include <stdlib.h>

#include <limits>

#include "base/logging.h"
#include "base/test/test_timeouts.h"
#include "base/threading/platform_thread.h"  // For |Sleep()|.
#include "build/build_config.h"

namespace mojo {
namespace system {
namespace test {

MojoDeadline DeadlineFromMilliseconds(unsigned milliseconds) {
  return static_cast<MojoDeadline>(milliseconds) * 1000;
}

MojoDeadline EpsilonDeadline() {
// Currently, |tiny_timeout()| is usually 100 ms (possibly scaled under ASAN,
// etc.). Based on this, set it to (usually be) 30 ms on Android and 20 ms
// elsewhere. (We'd like this to be as small as possible, without making things
// flaky)
#if defined(OS_ANDROID)
  return (TinyDeadline() * 3) / 10;
#else
  return (TinyDeadline() * 2) / 10;
#endif
}

MojoDeadline TinyDeadline() {
  return static_cast<MojoDeadline>(
      TestTimeouts::tiny_timeout().InMicroseconds());
}

MojoDeadline ActionDeadline() {
  return static_cast<MojoDeadline>(
      TestTimeouts::action_timeout().InMicroseconds());
}

void Sleep(MojoDeadline deadline) {
  CHECK_LE(deadline,
           static_cast<MojoDeadline>(std::numeric_limits<int64_t>::max()));
  base::PlatformThread::Sleep(
      base::TimeDelta::FromMicroseconds(static_cast<int64_t>(deadline)));
}

// TODO(vtl): Replace all of this implementation with suitable use of C++11
// <random> when we can.
int RandomInt(int min, int max) {
  DCHECK_LE(min, max);
  DCHECK_LE(static_cast<int64_t>(max) - min, RAND_MAX);
  DCHECK_LT(static_cast<int64_t>(max) - min, std::numeric_limits<int>::max());

  // This is in-range for an |int| due to the above.
  int range = max - min + 1;
  int max_valid = (RAND_MAX / range) * range - 1;
  int value;
  do {
    value = rand();
  } while (value > max_valid);
  return min + (value % range);
}

Stopwatch::Stopwatch() {
}

Stopwatch::~Stopwatch() {
}

void Stopwatch::Start() {
  start_time_ = platform_support_.GetTimeTicksNow();
}

MojoDeadline Stopwatch::Elapsed() {
  int64_t result = platform_support_.GetTimeTicksNow() - start_time_;
  // |DCHECK_GE|, not |CHECK_GE|, since this may be performance-important.
  DCHECK_GE(result, 0);
  return static_cast<MojoDeadline>(result);
}

}  // namespace test
}  // namespace system
}  // namespace mojo
