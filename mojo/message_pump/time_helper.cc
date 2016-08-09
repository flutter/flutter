// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/message_pump/time_helper.h"

#include "base/time/tick_clock.h"

namespace mojo {
namespace common {

namespace {

base::TickClock* tick_clock = NULL;

}  // namespace

namespace test {

void SetTickClockForTest(base::TickClock* clock) {
  tick_clock = clock;
}
}  // namespace test

namespace internal {

base::TimeTicks NowTicks() {
  return tick_clock ? tick_clock->NowTicks() : base::TimeTicks::Now();
}

}  // namespace internal
}  // namespace common
}  // namespace mojo
