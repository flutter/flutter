// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_impl.h"

#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "gtest/gtest.h"

#define TIMESENSITIVE(x) TimeSensitiveTest_##x

TEST(MessageLoopImpl, TIMESENSITIVE(WakeUpTimersAreSingletons)) {
  auto loop_impl = fml::MessageLoopImpl::Create();

  const auto t1 = fml::TimeDelta::FromMilliseconds(10);
  const auto t2 = fml::TimeDelta::FromMilliseconds(30);

  const auto begin = fml::TimePoint::Now();

  // Register a task scheduled in the future. This schedules a WakeUp call on
  // the MessageLoopImpl with that fml::TimePoint.
  loop_impl->PostTask(
      [&]() {
        auto delta = fml::TimePoint::Now() - begin;
        auto ms = delta.ToMillisecondsF();
        ASSERT_GE(ms, 20);
        ASSERT_LE(ms, 40);

        loop_impl->Terminate();
      },
      begin + t1);

  // Call WakeUp manually to change the WakeUp time further in the future. If
  // the timer is correctly set up to be rearmed instead of a task being
  // scheduled for each WakeUp, the above task will be executed at t2 instead of
  // t1 now.
  loop_impl->WakeUp(begin + t2);

  loop_impl->Run();
}
