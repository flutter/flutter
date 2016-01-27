// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/test_stopwatch.h"

#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/test/timeouts.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::system::test::EpsilonTimeout;

namespace mojo {
namespace platform {
namespace test {
namespace {

TEST(TestStopwatchTest, Basic) {
  Stopwatch s;

  s.Start();
  MojoDeadline e1 = s.Elapsed();
  EXPECT_LT(e1, EpsilonTimeout());

  MojoDeadline e2 = s.Elapsed();
  EXPECT_LT(e2, e1 + EpsilonTimeout());

  ThreadSleep(2 * EpsilonTimeout());
  MojoDeadline e3 = s.Elapsed();
  EXPECT_GT(e3, e2 + EpsilonTimeout());
  EXPECT_LT(e3, e2 + 3 * EpsilonTimeout());

  // Calling |Start()| again resets everything.
  s.Start();
  MojoDeadline e4 = s.Elapsed();
  EXPECT_LT(e4, EpsilonTimeout());
}

}  // namespace
}  // namespace test
}  // namespace platform
}  // namespace mojo
