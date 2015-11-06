// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/stopwatch.h"

#include <stdint.h>

#include "base/logging.h"

namespace mojo {
namespace system {
namespace test {

Stopwatch::Stopwatch() {}

Stopwatch::~Stopwatch() {}

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
