// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tests of CancellationFlag class.

#include "base/synchronization/cancellation_flag.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/spin_wait.h"
#include "base/threading/thread.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

namespace base {

namespace {

//------------------------------------------------------------------------------
// Define our test class.
//------------------------------------------------------------------------------

void CancelHelper(CancellationFlag* flag) {
#if GTEST_HAS_DEATH_TEST
  ASSERT_DEBUG_DEATH(flag->Set(), "");
#endif
}

TEST(CancellationFlagTest, SimpleSingleThreadedTest) {
  CancellationFlag flag;
  ASSERT_FALSE(flag.IsSet());
  flag.Set();
  ASSERT_TRUE(flag.IsSet());
}

TEST(CancellationFlagTest, DoubleSetTest) {
  CancellationFlag flag;
  ASSERT_FALSE(flag.IsSet());
  flag.Set();
  ASSERT_TRUE(flag.IsSet());
  flag.Set();
  ASSERT_TRUE(flag.IsSet());
}

TEST(CancellationFlagTest, SetOnDifferentThreadDeathTest) {
  // Checks that Set() can't be called from any other thread.
  // CancellationFlag should die on a DCHECK if Set() is called from
  // other thread.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  Thread t("CancellationFlagTest.SetOnDifferentThreadDeathTest");
  ASSERT_TRUE(t.Start());
  ASSERT_TRUE(t.message_loop());
  ASSERT_TRUE(t.IsRunning());

  CancellationFlag flag;
  t.task_runner()->PostTask(FROM_HERE, base::Bind(&CancelHelper, &flag));
}

}  // namespace

}  // namespace base
