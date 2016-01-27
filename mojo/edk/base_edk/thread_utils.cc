// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the functions declared in
// //mojo/edk/platform/thread_utils.h.

#include "mojo/edk/platform/thread_utils.h"

#include <stdint.h>

#include <limits>

#include "base/logging.h"
#include "base/threading/platform_thread.h"
#include "base/time/time.h"

namespace mojo {
namespace platform {

void ThreadYield() {
  base::PlatformThread::YieldCurrentThread();
}

void ThreadSleep(MojoDeadline duration) {
  // Note: This also effectively checks that |duration| isn't
  // |MOJO_DEADLINE_INDEFINITE|.
  DCHECK_LE(duration,
            static_cast<MojoDeadline>(std::numeric_limits<int64_t>::max()));

  base::PlatformThread::Sleep(
      base::TimeDelta::FromMicroseconds(static_cast<int64_t>(duration)));
}

}  // namespace platform
}  // namespace mojo
