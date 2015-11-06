// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/sleep.h"

#include <limits>

#include "base/logging.h"
#include "base/threading/platform_thread.h"  // For |Sleep()|.
#include "base/time/time.h"
#include "mojo/edk/system/test/timeouts.h"

namespace mojo {
namespace system {
namespace test {

void Sleep(MojoDeadline duration) {
  CHECK_LE(duration,
           static_cast<MojoDeadline>(std::numeric_limits<int64_t>::max()));
  base::PlatformThread::Sleep(
      base::TimeDelta::FromMicroseconds(static_cast<int64_t>(duration)));
}

void SleepMilliseconds(unsigned duration_milliseconds) {
  Sleep(DeadlineFromMilliseconds(duration_milliseconds));
}

}  // namespace test
}  // namespace system
}  // namespace mojo
