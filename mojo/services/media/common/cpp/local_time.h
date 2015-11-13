// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>
#include <chrono>  // NOLINT(build/c++11)

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_LOCAL_TIME_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_LOCAL_TIME_H_

// TODO(johngro): As we add support for other environments, extend this list.
#if defined(OS_POSIX)
#include "mojo/services/media/common/cpp/platform/posix/local_time.h"
#else
// TODO(johngro): consider adding a #warning or #info to inform the user that
// they are using the generic implementation of LocalTime, and really should get
// around to implementing proper platform support ASAP.
#include "mojo/services/media/common/cpp/platform/generic/local_time.h"
#endif

namespace mojo {
namespace media {
namespace local_time {

using Time = Clock::time_point;
using Duration = Clock::duration;

// Conversion from scalar types to Duration
template<class T>
static inline constexpr Duration from_sec(const T& d) {
    return std::chrono::duration_cast<Duration>(std::chrono::duration<T>(d));
}

template<class T>
static inline constexpr Duration from_msec(const T& d) {
    return std::chrono::duration_cast<Duration>(
        std::chrono::duration<T, std::milli>(d));
}

template<class T>
static inline constexpr Duration from_usec(const T& d) {
    return std::chrono::duration_cast<Duration>(
        std::chrono::duration<T, std::micro>(d));
}

template<class T>
static inline constexpr Duration from_nsec(const T& d) {
    return std::chrono::duration_cast<Duration>(
        std::chrono::duration<T, std::nano>(d));
}


// Conversion from Duration to scalar types
template<class T>
static inline constexpr T to_sec(const Duration& d) {
    return std::chrono::duration_cast<
      std::chrono::duration<T, std::ratio<1, 1>>>(d).count();
}

template<class T>
static inline constexpr T to_msec(const Duration& d) {
    return std::chrono::duration_cast<
      std::chrono::duration<T, std::milli>>(d).count();
}

template<class T>
static inline constexpr T to_usec(const Duration& d) {
    return std::chrono::duration_cast<
      std::chrono::duration<T, std::micro>>(d).count();
}

template<class T>
static inline constexpr T to_nsec(const Duration& d) {
    return std::chrono::duration_cast<
      std::chrono::duration<T, std::nano> >(d).count();
}

}  // namespace local_time

// Notes:
// LocalTimes (as reported by the LocalClock) are an implementation of a
// std::chrono clock.  They are...
//
// + High Resolution
// + Monotonic
// + Suitable for communicating with platform abstractions which use absolute
//   times.  For example, a kernel alarm device abstraction should be able to
//   use LocalTimes to schedule alarms.
//
// The generic implementation of LocalClock is simply an alias for
// std::chrono:steady_clock, and as such provides no guarantees about platform
// interactions.  It is present simply as a placeholder to allow code to compile
// as a new platform is brought up.
using LocalClock = local_time::Clock;
using LocalTime = local_time::Time;
using LocalDuration = local_time::Duration;

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_LOCAL_TIME_H_
