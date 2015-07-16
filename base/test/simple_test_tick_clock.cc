// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/simple_test_tick_clock.h"

#include "base/logging.h"

namespace base {

SimpleTestTickClock::SimpleTestTickClock() {}

SimpleTestTickClock::~SimpleTestTickClock() {}

TimeTicks SimpleTestTickClock::NowTicks() {
  AutoLock lock(lock_);
  return now_ticks_;
}

void SimpleTestTickClock::Advance(TimeDelta delta) {
  AutoLock lock(lock_);
  DCHECK(delta >= TimeDelta());
  now_ticks_ += delta;
}

}  // namespace base
