// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/thread.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

FLUTTER_ASSERT_NOT_ARC
namespace {
fml::RefPtr<fml::TaskRunner> CreateNewThread(std::string name) {
  auto thread = std::make_unique<fml::Thread>(name);
  auto runner = thread->GetTaskRunner();
  return runner;
}
}  // namespace

@interface VSyncClient (Testing)

- (CADisplayLink*)getDisplayLink;
- (void)onDisplayLink:(CADisplayLink*)link;

@end

@interface VsyncWaiterIosTest : XCTestCase
@end

@implementation VsyncWaiterIosTest

- (void)testSetAllowPauseAfterVsyncCorrect {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  VSyncClient* vsyncClient = [[[VSyncClient alloc]
      initWithTaskRunner:thread_task_runner
                callback:[](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {}]
      autorelease];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  vsyncClient.allowPauseAfterVsync = NO;
  [vsyncClient await];
  [vsyncClient onDisplayLink:link];
  XCTAssertFalse(link.isPaused);

  vsyncClient.allowPauseAfterVsync = YES;
  [vsyncClient await];
  [vsyncClient onDisplayLink:link];
  XCTAssertTrue(link.isPaused);

  [vsyncClient release];
}

- (void)testSetCorrectVariableRefreshRates {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  auto callback = [](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {};
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"])
      .andReturn(@YES);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  VSyncClient* vsyncClient = [[[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                             callback:callback] autorelease];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  if (@available(iOS 15.0, *)) {
    XCTAssertEqual(link.preferredFrameRateRange.maximum, maxFrameRate);
    XCTAssertEqual(link.preferredFrameRateRange.preferred, maxFrameRate);
    XCTAssertEqual(link.preferredFrameRateRange.minimum, maxFrameRate / 2);
  } else {
    XCTAssertEqual(link.preferredFramesPerSecond, maxFrameRate);
  }
  [vsyncClient release];
}

- (void)testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  auto callback = [](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {};
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"])
      .andReturn(@NO);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  VSyncClient* vsyncClient = [[[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                             callback:callback] autorelease];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  if (@available(iOS 15.0, *)) {
    XCTAssertEqual(link.preferredFrameRateRange.maximum, 0);
    XCTAssertEqual(link.preferredFrameRateRange.preferred, 0);
    XCTAssertEqual(link.preferredFrameRateRange.minimum, 0);
  } else {
    XCTAssertEqual(link.preferredFramesPerSecond, 0);
  }
  [vsyncClient release];
}

- (void)testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotSet {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  auto callback = [](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {};
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  VSyncClient* vsyncClient = [[[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                             callback:callback] autorelease];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  if (@available(iOS 15.0, *)) {
    XCTAssertEqual(link.preferredFrameRateRange.maximum, 0);
    XCTAssertEqual(link.preferredFrameRateRange.preferred, 0);
    XCTAssertEqual(link.preferredFrameRateRange.minimum, 0);
  } else {
    XCTAssertEqual(link.preferredFramesPerSecond, 0);
  }
  [vsyncClient release];
}

- (void)testAwaitAndPauseWillWorkCorrectly {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  VSyncClient* vsyncClient = [[[VSyncClient alloc]
      initWithTaskRunner:thread_task_runner
                callback:[](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {}]
      autorelease];

  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  [vsyncClient await];
  XCTAssertFalse(link.isPaused);

  [vsyncClient pause];
  XCTAssertTrue(link.isPaused);

  [vsyncClient release];
}

@end
