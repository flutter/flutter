// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/sleep.h"

#include "mojo/edk/system/test/stopwatch.h"
#include "mojo/edk/system/test/timeouts.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace test {
namespace {

TEST(SleepTest, Sleep) {
  Stopwatch stopwatch;

  stopwatch.Start();
  Sleep(0ULL);
  EXPECT_LT(stopwatch.Elapsed(), EpsilonTimeout());

  stopwatch.Start();
  Sleep(2 * EpsilonTimeout());
  MojoDeadline elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, EpsilonTimeout());
  EXPECT_LT(elapsed, 3 * EpsilonTimeout());
}

TEST(SleepTest, SleepMilliseconds) {
  Stopwatch stopwatch;

  stopwatch.Start();
  SleepMilliseconds(0U);
  EXPECT_LT(stopwatch.Elapsed(), EpsilonTimeout());

  const MojoDeadline kMillisecondsPerMicrosecond = 1000ULL;
  unsigned epsilon_ms =
      static_cast<unsigned>(EpsilonTimeout() / kMillisecondsPerMicrosecond);
  stopwatch.Start();
  SleepMilliseconds(2 * epsilon_ms);
  MojoDeadline elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, EpsilonTimeout());
  EXPECT_LT(elapsed, 3 * EpsilonTimeout());
}

}  // namespace
}  // namespace test
}  // namespace system
}  // namespace mojo
