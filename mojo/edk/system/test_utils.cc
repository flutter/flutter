// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test_utils.h"

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
// Originally, our epsilon timeout was 10 ms, which was mostly fine but flaky on
// some Windows bots. I don't recall ever seeing flakes on other bots. At 30 ms
// tests seem reliable on Windows bots, but not at 25 ms. We'd like this timeout
// to be as small as possible (see the description in the .h file).
//
// Currently, |tiny_timeout()| is usually 100 ms (possibly scaled under ASAN,
// etc.). Based on this, set it to (usually be) 30 ms on Windows and 20 ms
// elsewhere.
#if defined(OS_WIN) || defined(OS_ANDROID)
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

Stopwatch::Stopwatch() {
}

Stopwatch::~Stopwatch() {
}

void Stopwatch::Start() {
  start_time_ = base::TimeTicks::Now();
}

MojoDeadline Stopwatch::Elapsed() {
  int64_t result = (base::TimeTicks::Now() - start_time_).InMicroseconds();
  // |DCHECK_GE|, not |CHECK_GE|, since this may be performance-important.
  DCHECK_GE(result, 0);
  return static_cast<MojoDeadline>(result);
}

}  // namespace test
}  // namespace system
}  // namespace mojo
