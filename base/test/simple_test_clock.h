// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_SIMPLE_TEST_CLOCK_H_
#define BASE_TEST_SIMPLE_TEST_CLOCK_H_

#include "base/compiler_specific.h"
#include "base/synchronization/lock.h"
#include "base/time/clock.h"
#include "base/time/time.h"

namespace base {

// SimpleTestClock is a Clock implementation that gives control over
// the returned Time objects.  All methods may be called from any
// thread.
class SimpleTestClock : public Clock {
 public:
  // Starts off with a clock set to Time().
  SimpleTestClock();
  ~SimpleTestClock() override;

  Time Now() override;

  // Advances the clock by |delta|.
  void Advance(TimeDelta delta);

  // Sets the clock to the given time.
  void SetNow(Time now);

 private:
  // Protects |now_|.
  Lock lock_;

  Time now_;
};

}  // namespace base

#endif  // BASE_TEST_SIMPLE_TEST_CLOCK_H_
