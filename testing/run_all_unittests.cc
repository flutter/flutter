// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/build_config.h"
#include "flutter/testing/test_timeout_listener.h"
#include "gtest/gtest.h"

#ifdef OS_IOS
#include <asl.h>
#endif  // OS_IOS

int main(int argc, char** argv) {
#ifdef OS_IOS
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_NOTICE, STDOUT_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_ERR, STDERR_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
#endif  // OS_IOS

  ::testing::InitGoogleTest(&argc, argv);
  auto timeout_listener = new flutter::testing::TestTimeoutListener();
  auto& listeners = ::testing::UnitTest::GetInstance()->listeners();
  listeners.Append(timeout_listener);
  auto result = RUN_ALL_TESTS();
  delete listeners.Release(timeout_listener);
  return result;
}
