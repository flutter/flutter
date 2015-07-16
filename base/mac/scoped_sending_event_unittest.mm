// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/mac/scoped_sending_event.h"

#import <Foundation/Foundation.h>

#include "base/mac/scoped_nsobject.h"
#include "testing/gtest/include/gtest/gtest.h"

@interface ScopedSendingEventTestCrApp : NSObject <CrAppControlProtocol> {
 @private
  BOOL handlingSendEvent_;
}
@property(nonatomic, assign, getter=isHandlingSendEvent) BOOL handlingSendEvent;
@end

@implementation ScopedSendingEventTestCrApp
@synthesize handlingSendEvent = handlingSendEvent_;
@end

namespace {

class ScopedSendingEventTest : public testing::Test {
 public:
  ScopedSendingEventTest() : app_([[ScopedSendingEventTestCrApp alloc] init]) {
    NSApp = app_.get();
  }
  ~ScopedSendingEventTest() override { NSApp = nil; }

 private:
  base::scoped_nsobject<ScopedSendingEventTestCrApp> app_;
};

// Sets the flag within scope, resets when leaving scope.
TEST_F(ScopedSendingEventTest, SetHandlingSendEvent) {
  id<CrAppProtocol> app = NSApp;
  EXPECT_FALSE([app isHandlingSendEvent]);
  {
    base::mac::ScopedSendingEvent is_handling_send_event;
    EXPECT_TRUE([app isHandlingSendEvent]);
  }
  EXPECT_FALSE([app isHandlingSendEvent]);
}

// Nested call restores previous value rather than resetting flag.
TEST_F(ScopedSendingEventTest, NestedSetHandlingSendEvent) {
  id<CrAppProtocol> app = NSApp;
  EXPECT_FALSE([app isHandlingSendEvent]);
  {
    base::mac::ScopedSendingEvent is_handling_send_event;
    EXPECT_TRUE([app isHandlingSendEvent]);
    {
      base::mac::ScopedSendingEvent nested_is_handling_send_event;
      EXPECT_TRUE([app isHandlingSendEvent]);
    }
    EXPECT_TRUE([app isHandlingSendEvent]);
  }
  EXPECT_FALSE([app isHandlingSendEvent]);
}

}  // namespace
