// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/user_action_tester.h"

#include "base/metrics/user_metrics.h"
#include "base/metrics/user_metrics_action.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

const char kUserAction1[] = "user.action.1";
const char kUserAction2[] = "user.action.2";
const char kUserAction3[] = "user.action.3";

// Record an action and cause all ActionCallback observers to be notified.
void RecordAction(const char user_action[]) {
  base::RecordAction(base::UserMetricsAction(user_action));
}

}  // namespace

// Verify user action counts are zero initially.
TEST(UserActionTesterTest, GetActionCountWhenNoActionsHaveBeenRecorded) {
  UserActionTester user_action_tester;
  EXPECT_EQ(0, user_action_tester.GetActionCount(kUserAction1));
}

// Verify user action counts are tracked properly.
TEST(UserActionTesterTest, GetActionCountWhenActionsHaveBeenRecorded) {
  UserActionTester user_action_tester;

  RecordAction(kUserAction1);
  RecordAction(kUserAction2);
  RecordAction(kUserAction2);

  EXPECT_EQ(1, user_action_tester.GetActionCount(kUserAction1));
  EXPECT_EQ(2, user_action_tester.GetActionCount(kUserAction2));
  EXPECT_EQ(0, user_action_tester.GetActionCount(kUserAction3));
}

// Verify no seg faults occur when resetting action counts when none have been
// recorded.
TEST(UserActionTesterTest, ResetCountsWhenNoActionsHaveBeenRecorded) {
  UserActionTester user_action_tester;
  user_action_tester.ResetCounts();
}

// Verify user action counts are set to zero on a ResetCounts.
TEST(UserActionTesterTest, ResetCountsWhenActionsHaveBeenRecorded) {
  UserActionTester user_action_tester;

  RecordAction(kUserAction1);
  RecordAction(kUserAction1);
  RecordAction(kUserAction2);
  user_action_tester.ResetCounts();

  EXPECT_EQ(0, user_action_tester.GetActionCount(kUserAction1));
  EXPECT_EQ(0, user_action_tester.GetActionCount(kUserAction2));
  EXPECT_EQ(0, user_action_tester.GetActionCount(kUserAction3));
}

// Verify the UserActionsTester is notified when base::RecordAction is called.
TEST(UserActionTesterTest, VerifyUserActionTesterListensForUserActions) {
  UserActionTester user_action_tester;

  base::RecordAction(base::UserMetricsAction(kUserAction1));

  EXPECT_EQ(1, user_action_tester.GetActionCount(kUserAction1));
}

// Verify the UserActionsTester is notified when base::RecordComputedAction is
// called.
TEST(UserActionTesterTest,
     VerifyUserActionTesterListensForComputedUserActions) {
  UserActionTester user_action_tester;

  base::RecordComputedAction(kUserAction1);

  EXPECT_EQ(1, user_action_tester.GetActionCount(kUserAction1));
}

}  // namespace base
