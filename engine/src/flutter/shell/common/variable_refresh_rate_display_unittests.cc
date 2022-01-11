// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "variable_refresh_rate_display.h"
#include "vsync_waiters_test.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(VariableRefreshRateDisplayTest, ReportCorrectInitialRefreshRate) {
  auto refresh_rate_reporter = std::make_unique<TestRefreshRateReporter>(60);
  auto display =
      flutter::VariableRefreshRateDisplay(*refresh_rate_reporter.get());
  ASSERT_EQ(display.GetRefreshRate(), 60);
}

TEST(VariableRefreshRateDisplayTest, ReportCorrectRefreshRateWhenUpdated) {
  auto refresh_rate_reporter = std::make_unique<TestRefreshRateReporter>(60);
  auto display =
      flutter::VariableRefreshRateDisplay(*refresh_rate_reporter.get());
  refresh_rate_reporter->UpdateRefreshRate(30);
  ASSERT_EQ(display.GetRefreshRate(), 30);
}

}  // namespace testing
}  // namespace flutter
