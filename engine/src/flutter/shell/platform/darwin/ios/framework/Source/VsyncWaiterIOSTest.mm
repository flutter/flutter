// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

@interface VsyncWaiterIOSTest : XCTestCase
@end

@implementation VsyncWaiterIOSTest

- (void)testSnapDurationWithValidDuration {
  // 60Hz: 1/60 = 0.016666...
  CFTimeInterval duration = 0.016667;
  CFTimeInterval snapped = flutter::VsyncWaiterIOS::SnapDuration(duration, 60.0);
  XCTAssertEqualWithAccuracy(snapped, 1.0 / 60.0, 0.0001);

  // 120Hz: 1/120 = 0.008333...
  duration = 0.008334;
  snapped = flutter::VsyncWaiterIOS::SnapDuration(duration, 120.0);
  XCTAssertEqualWithAccuracy(snapped, 1.0 / 120.0, 0.0001);
}

- (void)testSnapDurationWithInvalidDuration {
  // Zero duration should fallback to max_refresh_rate.
  CFTimeInterval snapped = flutter::VsyncWaiterIOS::SnapDuration(0.0, 120.0);
  XCTAssertEqualWithAccuracy(snapped, 1.0 / 120.0, 0.0001);

  // Negative duration should fallback to max_refresh_rate.
  snapped = flutter::VsyncWaiterIOS::SnapDuration(-0.1, 80.0);
  XCTAssertEqualWithAccuracy(snapped, 1.0 / 80.0, 0.0001);
}

- (void)testSnapDurationWithZeroMaxRefreshRateFallback {
  // If duration is invalid AND max_refresh_rate is 0, fallback to 60Hz.
  CFTimeInterval snapped = flutter::VsyncWaiterIOS::SnapDuration(0.0, 0.0);
  XCTAssertEqualWithAccuracy(snapped, 1.0 / 60.0, 0.0001);

  snapped = flutter::VsyncWaiterIOS::SnapDuration(-1.0, -10.0);
  XCTAssertEqualWithAccuracy(snapped, 1.0 / 60.0, 0.0001);
}

@end
