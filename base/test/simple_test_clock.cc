// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/simple_test_clock.h"

namespace base {

SimpleTestClock::SimpleTestClock() {}

SimpleTestClock::~SimpleTestClock() {}

Time SimpleTestClock::Now() {
  AutoLock lock(lock_);
  return now_;
}

void SimpleTestClock::Advance(TimeDelta delta) {
  AutoLock lock(lock_);
  now_ += delta;
}

void SimpleTestClock::SetNow(Time now) {
  AutoLock lock(lock_);
  now_ = now;
}

}  // namespace base
