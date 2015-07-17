// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/call_with_eh_frame.h"

#import <Foundation/Foundation.h>

#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace mac {
namespace {

class CallWithEHFrameTest : public testing::Test {
 protected:
  void ThrowException() {
    [NSArray arrayWithObject:nil];
  }
};

// Catching from within the EHFrame is allowed.
TEST_F(CallWithEHFrameTest, CatchExceptionHigher) {
  bool __block saw_exception = false;
  base::mac::CallWithEHFrame(^{
    @try {
      ThrowException();
    } @catch (NSException* exception) {
      saw_exception = true;
    }
  });
  EXPECT_TRUE(saw_exception);
}

// Trying to catch an exception outside the EHFrame is blocked.
TEST_F(CallWithEHFrameTest, CatchExceptionLower) {
  auto catch_exception_lower = ^{
    bool saw_exception = false;
    @try {
      base::mac::CallWithEHFrame(^{
        ThrowException();
      });
    } @catch (NSException* exception) {
      saw_exception = true;
    }
    ASSERT_FALSE(saw_exception);
  };
  EXPECT_DEATH(catch_exception_lower(), "");
}

}  // namespace
}  // namespace mac
}  // namespace base
