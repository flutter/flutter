// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test of classes in tracked_time.cc

#include "base/profiler/tracked_time.h"
#include "base/time/time.h"
#include "base/tracked_objects.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace tracked_objects {

TEST(TrackedTimeTest, TrackedTimerMilliseconds) {
  // First make sure we basicallly transfer simple milliseconds values as
  // expected.  Most critically, things should not become null.
  int32 kSomeMilliseconds = 243;  // Some example times.
  int64 kReallyBigMilliseconds = (1LL << 35) + kSomeMilliseconds;

  TrackedTime some = TrackedTime() +
      Duration::FromMilliseconds(kSomeMilliseconds);
  EXPECT_EQ(kSomeMilliseconds, (some - TrackedTime()).InMilliseconds());
  EXPECT_FALSE(some.is_null());

  // Now create a big time, to check that it is wrapped modulo 2^32.
  base::TimeTicks big = base::TimeTicks() +
      base::TimeDelta::FromMilliseconds(kReallyBigMilliseconds);
  EXPECT_EQ(kReallyBigMilliseconds, (big - base::TimeTicks()).InMilliseconds());

  TrackedTime wrapped_big(big);
  // Expect wrapping at 32 bits.
  EXPECT_EQ(kSomeMilliseconds, (wrapped_big - TrackedTime()).InMilliseconds());
}

TEST(TrackedTimeTest, TrackedTimerDuration) {
  int kFirstMilliseconds = 793;
  int kSecondMilliseconds = 14889;

  Duration first = Duration::FromMilliseconds(kFirstMilliseconds);
  Duration second = Duration::FromMilliseconds(kSecondMilliseconds);

  EXPECT_EQ(kFirstMilliseconds, first.InMilliseconds());
  EXPECT_EQ(kSecondMilliseconds, second.InMilliseconds());

  Duration sum = first + second;
  EXPECT_EQ(kFirstMilliseconds + kSecondMilliseconds, sum.InMilliseconds());
}

TEST(TrackedTimeTest, TrackedTimerVsTimeTicks) {
  // Make sure that our 32 bit timer is aligned with the TimeTicks() timer.

  // First get a 64 bit timer (which should not be null).
  base::TimeTicks ticks_before = base::TimeTicks::Now();
  EXPECT_FALSE(ticks_before.is_null());

  // Then get a 32 bit timer that can be be null when it wraps.
  TrackedTime now = TrackedTime::Now();

  // Then get a bracketing time.
  base::TimeTicks ticks_after = base::TimeTicks::Now();
  EXPECT_FALSE(ticks_after.is_null());

  // Now make sure that we bracketed our tracked time nicely.
  Duration before = now - TrackedTime(ticks_before);
  EXPECT_LE(0, before.InMilliseconds());
  Duration after = now - TrackedTime(ticks_after);
  EXPECT_GE(0, after.InMilliseconds());
}

TEST(TrackedTimeTest, TrackedTimerDisabled) {
  // Check to be sure disabling the collection of data induces a null time
  // (which we know will return much faster).
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::DEACTIVATED);
  // Since we disabled tracking, we should get a null response.
  TrackedTime track_now = ThreadData::Now();
  EXPECT_TRUE(track_now.is_null());
}

TEST(TrackedTimeTest, TrackedTimerEnabled) {
  ThreadData::InitializeAndSetTrackingStatus(ThreadData::PROFILING_ACTIVE);
  // Make sure that when we enable tracking, we get a real timer result.

  // First get a 64 bit timer (which should not be null).
  base::TimeTicks ticks_before = base::TimeTicks::Now();
  EXPECT_FALSE(ticks_before.is_null());

  // Then get a 32 bit timer that can be null when it wraps.
  // Crtical difference from  the TrackedTimerVsTimeTicks test, is that we use
  // ThreadData::Now().  It can sometimes return the null time.
  TrackedTime now = ThreadData::Now();

  // Then get a bracketing time.
  base::TimeTicks ticks_after = base::TimeTicks::Now();
  EXPECT_FALSE(ticks_after.is_null());

  // Now make sure that we bracketed our tracked time nicely.
  Duration before = now - TrackedTime(ticks_before);
  EXPECT_LE(0, before.InMilliseconds());
  Duration after = now - TrackedTime(ticks_after);
  EXPECT_GE(0, after.InMilliseconds());
}

}  // namespace tracked_objects
