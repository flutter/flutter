// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_H_

#include <stdint.h>
#include <chrono>  // NOLINT(build/c++11)

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

// Some helpful constants and static methods relating to timelines.
class Timeline {
 public:
  // Returns the current local time in nanoseconds since epoch.
  static int64_t local_now() {
    return local_time::Clock::now().time_since_epoch().count();
  }

  template <typename T>
  static constexpr int64_t ns_from_seconds(T seconds) {
    return static_cast<int64_t>(seconds * std::nano::den);
  }

  template <typename T>
  static constexpr int64_t ns_from_ms(T milliseconds) {
    return static_cast<int64_t>(milliseconds *
                                (std::nano::den / std::milli::den));
  }

  template <typename T>
  static constexpr int64_t ns_from_us(T microseconds) {
    return static_cast<int64_t>(microseconds *
                                (std::nano::den / std::micro::den));
  }
};

}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_TIMELINE_H_
