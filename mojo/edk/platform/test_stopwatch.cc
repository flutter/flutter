// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/test_stopwatch.h"

#include <assert.h>
#include <stdint.h>

#include "mojo/edk/platform/time_ticks.h"

namespace mojo {
namespace platform {
namespace test {

void Stopwatch::Start() {
  start_time_ = GetTimeTicks();
}

MojoDeadline Stopwatch::Elapsed() {
  int64_t result = GetTimeTicks() - start_time_;
  assert(result >= 0);
  return static_cast<MojoDeadline>(result);
}

}  // namespace test
}  // namespace platform
}  // namespace mojo
