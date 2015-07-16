// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_listener_ios.h"

#import <Foundation/Foundation.h>

#include "base/mac/scoped_nsautorelease_pool.h"
#include "testing/gtest/include/gtest/gtest.h"

// The iOS watchdog timer will kill an app that doesn't spin the main event
// loop often enough. This uses a Gtest TestEventListener to spin the current
// loop after each test finishes. However, if any individual test takes too
// long, it is still possible that the app will get killed.

namespace {

class IOSRunLoopListener : public testing::EmptyTestEventListener {
 public:
  virtual void OnTestEnd(const testing::TestInfo& test_info);
};

void IOSRunLoopListener::OnTestEnd(const testing::TestInfo& test_info) {
  base::mac::ScopedNSAutoreleasePool scoped_pool;

  // At the end of the test, spin the default loop for a moment.
  NSDate* stop_date = [NSDate dateWithTimeIntervalSinceNow:0.001];
  [[NSRunLoop currentRunLoop] runUntilDate:stop_date];
}

}  // namespace


namespace base {
namespace test_listener_ios {

void RegisterTestEndListener() {
  testing::TestEventListeners& listeners =
      testing::UnitTest::GetInstance()->listeners();
  listeners.Append(new IOSRunLoopListener);
}

}  // namespace test_listener_ios
}  // namespace base
