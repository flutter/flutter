// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_PLATFORM_POSIX_LOCAL_TIME_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_PLATFORM_POSIX_LOCAL_TIME_H_

#include <stdint.h>
#include <chrono>  // NOLINT(build/c++11)

namespace mojo {
namespace media {
namespace local_time {

class Clock {
 public:
  typedef int64_t                                  rep;
  typedef std::nano                                period;
  typedef std::chrono::duration<rep, period>       duration;
  typedef std::chrono::time_point<Clock, duration> time_point;

  /** This clock is monotonic */
  static constexpr bool is_steady = true;

  static time_point now() noexcept;
};

}  // namespace local_time
}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_PLATFORM_POSIX_LOCAL_TIME_H_
