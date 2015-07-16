// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_USER_ACTION_TESTER_H_
#define BASE_TEST_USER_ACTION_TESTER_H_

#include <map>
#include <string>

#include "base/metrics/user_metrics.h"

namespace base {

// This class observes and collects user action notifications that are sent
// by the tests, so that they can be examined afterwards for correctness.
// Note: This class is NOT thread-safe.
class UserActionTester {
 public:
  UserActionTester();
  ~UserActionTester();

  // Returns the number of times the given |user_action| occurred.
  int GetActionCount(const std::string& user_action) const;

  // Resets all user action counts to 0.
  void ResetCounts();

 private:
  typedef std::map<std::string, int> UserActionCountMap;

  // The callback that is notified when a user actions occurs.
  void OnUserAction(const std::string& user_action);

  // A map that tracks the number of times a user action has occurred.
  UserActionCountMap count_map_;

  // The callback that is added to the global action callback list.
  base::ActionCallback action_callback_;

  DISALLOW_COPY_AND_ASSIGN(UserActionTester);
};

}  // namespace base

#endif  // BASE_TEST_USER_ACTION_TESTER_H_
