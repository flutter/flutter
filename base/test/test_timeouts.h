// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_TIMEOUTS_H_
#define BASE_TEST_TEST_TIMEOUTS_H_

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/time/time.h"

// Returns common timeouts to use in tests. Makes it possible to adjust
// the timeouts for different environments (like Valgrind).
class TestTimeouts {
 public:
  // Initializes the timeouts. Non thread-safe. Should be called exactly once
  // by the test suite.
  static void Initialize();

  // Timeout for actions that are expected to finish "almost instantly".
  static base::TimeDelta tiny_timeout() {
    DCHECK(initialized_);
    return base::TimeDelta::FromMilliseconds(tiny_timeout_ms_);
  }

  // Timeout to wait for something to happen. If you are not sure
  // which timeout to use, this is the one you want.
  static base::TimeDelta action_timeout() {
    DCHECK(initialized_);
    return base::TimeDelta::FromMilliseconds(action_timeout_ms_);
  }

  // Timeout longer than the above, but still suitable to use
  // multiple times in a single test. Use if the timeout above
  // is not sufficient.
  static base::TimeDelta action_max_timeout() {
    DCHECK(initialized_);
    return base::TimeDelta::FromMilliseconds(action_max_timeout_ms_);
  }

  // Timeout for a single test launched used built-in test launcher.
  // Do not use outside of the test launcher.
  static base::TimeDelta test_launcher_timeout() {
    DCHECK(initialized_);
    return base::TimeDelta::FromMilliseconds(test_launcher_timeout_ms_);
  }

 private:
  static bool initialized_;

  static int tiny_timeout_ms_;
  static int action_timeout_ms_;
  static int action_max_timeout_ms_;
  static int test_launcher_timeout_ms_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(TestTimeouts);
};

#endif  // BASE_TEST_TEST_TIMEOUTS_H_
