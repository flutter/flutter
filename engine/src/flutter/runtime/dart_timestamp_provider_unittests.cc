// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_timestamp_provider.h"

#include <chrono>
#include <thread>

#include "flutter/fml/time/time_point.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DartTimestampProvider, DartClockIsMonotonic) {
  using namespace std::chrono_literals;
  const auto t1 = DartTimelineTicksSinceEpoch();
  std::this_thread::sleep_for(1us);
  const auto t2 = DartTimelineTicksSinceEpoch();
  std::this_thread::sleep_for(1us);
  const auto t3 = DartTimelineTicksSinceEpoch();
  EXPECT_LT(fml::TimePoint::Min(), t1);
  EXPECT_LE(t1, t2);
  EXPECT_LE(t2, t3);
  EXPECT_LT(t3, fml::TimePoint::Max());
}

}  // namespace testing
}  // namespace flutter
