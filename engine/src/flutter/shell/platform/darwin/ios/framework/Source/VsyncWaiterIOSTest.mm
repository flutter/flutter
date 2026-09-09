// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/fml/message_loop.h"
#import "flutter/shell/platform/darwin/ios/InternalFlutterSwift/InternalFlutterSwift.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

namespace {

flutter::TaskRunners CreateTestTaskRunners() {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  return flutter::TaskRunners("VsyncWaiterIOSTest", task_runner, task_runner, task_runner,
                              task_runner);
}

}  // namespace

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

- (void)testConstructorUsesInjectedDisplayLinkManagerRefreshRate {
  id mockDisplayLinkManager = OCMPartialMock([FlutterDisplayLinkManager shared]);
  [self addTeardownBlock:^{
    [mockDisplayLinkManager stopMocking];
  }];
  double maxFrameRate = 120;
  (void)[[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  flutter::TaskRunners taskRunners = CreateTestTaskRunners();
  auto waiter = std::make_unique<flutter::VsyncWaiterIOS>(taskRunners, mockDisplayLinkManager);

  XCTAssertEqual(waiter->GetMaxRefreshRateForTesting(), maxFrameRate);
}

- (void)testAwaitVSyncPicksUpRefreshRateChangesFromInjectedDisplayLinkManager {
  id mockDisplayLinkManager = OCMPartialMock([FlutterDisplayLinkManager shared]);
  [self addTeardownBlock:^{
    [mockDisplayLinkManager stopMocking];
  }];
  // A single stub whose return value is re-read on every invocation via the __block variable.
  // OCMock stubs aren't replaced by re-stubbing the same selector — the first-registered stub
  // keeps answering — so a fixed andReturnValue: can't model a value that changes over time.
  double initialFrameRate = 60;
  __block double refreshRate = initialFrameRate;
  OCMStub([mockDisplayLinkManager displayRefreshRate]).andDo(^(NSInvocation* invocation) {
    [invocation setReturnValue:&refreshRate];
  });

  flutter::TaskRunners taskRunners = CreateTestTaskRunners();
  auto waiter = std::make_unique<flutter::VsyncWaiterIOS>(taskRunners, mockDisplayLinkManager);
  XCTAssertEqual(waiter->GetMaxRefreshRateForTesting(), initialFrameRate);

  double updatedFrameRate = 120;
  refreshRate = updatedFrameRate;
  waiter->AwaitVSync();

  XCTAssertEqual(waiter->GetMaxRefreshRateForTesting(), updatedFrameRate);
}

@end
