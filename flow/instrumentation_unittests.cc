// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/instrumentation.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

using testing::Return;

namespace flutter {
namespace testing {

class MockRefreshRateUpdater : public Stopwatch::RefreshRateUpdater {
 public:
  MOCK_CONST_METHOD0(GetFrameBudget, fml::Milliseconds());
};

TEST(Instrumentation, GetDefaultFrameBudgetTest) {
  fml::Milliseconds frame_budget_60fps = fml::RefreshRateToFrameBudget(60);
  // The default constructor sets the frame_budget to 16.6667 (60 fps).
  FixedRefreshRateStopwatch stopwatch;
  fml::Milliseconds actual_frame_budget = stopwatch.GetFrameBudget();
  EXPECT_EQ(frame_budget_60fps, actual_frame_budget);
}

TEST(Instrumentation, GetOneShotFrameBudgetTest) {
  fml::Milliseconds frame_budget_90fps = fml::RefreshRateToFrameBudget(90);
  FixedRefreshRateStopwatch stopwatch(frame_budget_90fps);
  fml::Milliseconds actual_frame_budget = stopwatch.GetFrameBudget();
  EXPECT_EQ(frame_budget_90fps, actual_frame_budget);
}

TEST(Instrumentation, GetFrameBudgetFromUpdaterTest) {
  MockRefreshRateUpdater updater;
  fml::Milliseconds frame_budget_90fps = fml::RefreshRateToFrameBudget(90);
  EXPECT_CALL(updater, GetFrameBudget())
      .Times(1)
      .WillOnce(Return(frame_budget_90fps));
  Stopwatch stopwatch(updater);
  fml::Milliseconds actual_frame_budget = stopwatch.GetFrameBudget();
  EXPECT_EQ(frame_budget_90fps, actual_frame_budget);
}

}  // namespace testing
}  // namespace flutter
