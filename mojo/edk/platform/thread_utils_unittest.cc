// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/thread_utils.h"

#include "mojo/edk/platform/test_stopwatch.h"
#include "mojo/edk/system/test/timeouts.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::system::test::EpsilonTimeout;

namespace mojo {
namespace platform {
namespace {

TEST(ThreadUtilsTest, ThreadYield) {
  // It's pretty hard to test yield, other than maybe statistically (but tough
  // even then, since it'd be dependent on the number of cores). So just check
  // that it doesn't crash.
  ThreadYield();
}

TEST(ThreadUtilsTest, ThreadSleep) {
  test::Stopwatch stopwatch;

  stopwatch.Start();
  ThreadSleep(0ULL);
  EXPECT_LT(stopwatch.Elapsed(), EpsilonTimeout());

  stopwatch.Start();
  ThreadSleep(2 * EpsilonTimeout());
  MojoDeadline elapsed = stopwatch.Elapsed();
  EXPECT_GT(elapsed, EpsilonTimeout());
  EXPECT_LT(elapsed, 3 * EpsilonTimeout());
}

}  // namespace
}  // namespace platform
}  // namespace mojo
