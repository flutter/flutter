// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <time.h>

#include "mojo/public/cpp/environment/logging.h"
#include "mojo/services/media/common/cpp/platform/posix/local_time.h"

namespace mojo {
namespace media {
namespace local_time {

constexpr bool Clock::is_steady;

// TODO(johngro): Some toolchains (like the PNaCl toolchain) do not have a
// definition for CLOCK_BOOTTIME.  For now, use BOOTTIME if we can, and fallback
// on MONOTONIC if we can't.
//
// Moving forward, the platform abstractions for time should be moved entirely
// into the mojo core.  It would be nice to use MojoGetTimeTicksNow as the basis
// for media::local_time, but there are some issues which need to be addressed
// first.  Issues include...
// + Units for MGTTN are spec'ed as microseconds.  While not the worst in the
//   world, this is a bit coarse for media.
// + More importantly for media purposes, MGTTN is completely abstract.  No
//   guarantees are provided as to which clock in the system is being used or
//   how it relates to other clocks in the system.  For media clocks, we need to
//   know that...
// +++ Timestamps queried in userland come from the same clock as timestamps
//     queried by kernel drivers.
// +++ The chosen clock comes from the same root oscillator as the audio and
//     video outputs in the system.  This is a minor thing, as most systems have
//     only a single oscillator, but when there are multiple, this really
//     matters.  (Systems with multiple oscillators for multiple outputs are
//     even more rare, and require special consideration)
#ifdef CLOCK_BOOTTIME
static constexpr clockid_t CLOCK_SOURCE = CLOCK_BOOTTIME;
#else
static constexpr clockid_t CLOCK_SOURCE = CLOCK_MONOTONIC;
#endif

Clock::time_point Clock::now() noexcept {
  // It sure would be nice if we could just get a flat 64 bit representation of
  // the time, so we didn't have to do this expensive multiply.  Perhaps on FNL.
  //
  // It would also be Very Nice have our period be the actual period of the
  // underlying hardware oscillator, so we didn't have to normalize to
  // nanoseconds.  Since the period needs to be defined at compile time, and the
  // HW oscillator period may not even be constant, this is probably not
  // an achievable goal.
  struct timespec ts;
  int res = clock_gettime(CLOCK_SOURCE, &ts);
  MOJO_DCHECK(!res);

  int64_t now_ticks = ts.tv_sec;
  now_ticks *= 1000000000;
  now_ticks += ts.tv_nsec;

  return time_point(duration(now_ticks));
}

}  // namespace local_time
}  // namespace media
}  // namespace mojo
