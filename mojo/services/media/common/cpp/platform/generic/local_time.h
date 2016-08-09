// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_MEDIA_COMMON_CPP_PLATFORM_GENERIC_LOCAL_TIME_H_
#define MOJO_SERVICES_MEDIA_COMMON_CPP_PLATFORM_GENERIC_LOCAL_TIME_H_

#include <chrono>  // NOLINT(build/c++11)

namespace mojo {
namespace media {
namespace local_time {

using Clock = std::chrono::steady_clock;

}  // namespace local_time
}  // namespace media
}  // namespace mojo

#endif  // MOJO_SERVICES_MEDIA_COMMON_CPP_PLATFORM_GENERIC_LOCAL_TIME_H_
