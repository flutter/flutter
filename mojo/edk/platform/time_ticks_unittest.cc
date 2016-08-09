// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/time_ticks.h"

#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/test/timeouts.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::system::test::DeadlineFromMilliseconds;

namespace mojo {
namespace platform {
namespace {

TEST(TimeTicks, GetTimeTicks) {
  // It's hard to test this without assuming that other things work correctly.
  // So, first just check that it's weakly monotonic.
  MojoTimeTicks first = GetTimeTicks();
  EXPECT_GT(first, 0);
  MojoTimeTicks second = GetTimeTicks();
  EXPECT_LE(first, second);  // They're likely equal!

  // Next, assume that |ThreadSleep()| at least kind of works. Assume that the
  // clock resolution isn't *too* terrible, so that sleeping 20 ms will result
  // in the clock increasing.
  ThreadSleep(DeadlineFromMilliseconds(20u));
  MojoTimeTicks third = GetTimeTicks();
  EXPECT_LT(second, third);
}

}  // namespace
}  // namespace platform
}  // namespace mojo
