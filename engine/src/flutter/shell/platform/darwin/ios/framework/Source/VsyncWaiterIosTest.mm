// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <QuartzCore/QuartzCore.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/thread.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

FLUTTER_ASSERT_ARC
namespace {
fml::RefPtr<fml::TaskRunner> CreateNewThread(const std::string& name) {
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
  VSyncClient* vsyncClient = [[VSyncClient alloc]
      initWithTaskRunner:thread_task_runner
                callback:[](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {}];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  vsyncClient.allowPauseAfterVsync = NO;
  [vsyncClient await];
  [vsyncClient onDisplayLink:link];
  XCTAssertFalse(link.isPaused);

  vsyncClient.allowPauseAfterVsync = YES;
  [vsyncClient await];
  [vsyncClient onDisplayLink:link];
  XCTAssertTrue(link.isPaused);
}

- (void)testSetCorrectVariableRefreshRates {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  auto callback = [](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {};
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kCADisableMinimumFrameDurationOnPhoneKey])
      .andReturn(@YES);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, maxFrameRate / 2, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, maxFrameRate, 0.1);
  }
}

- (void)testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  auto callback = [](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {};
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kCADisableMinimumFrameDurationOnPhoneKey])
      .andReturn(@NO);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, 0, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, 0, 0.1);
  }
}

- (void)testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotSet {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  auto callback = [](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {};
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, 0, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, 0, 0.1);
  }
}

- (void)testAwaitAndPauseWillWorkCorrectly {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
  VSyncClient* vsyncClient = [[VSyncClient alloc]
      initWithTaskRunner:thread_task_runner
                callback:[](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {}];

  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  [vsyncClient await];
  XCTAssertFalse(link.isPaused);

  [vsyncClient pause];
  XCTAssertTrue(link.isPaused);
}

- (void)testAwaitSchedulesPredictedCallbackWhenPausedAndEnoughHeadroom {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");

  int callbackCount = 0;
  fml::TimePoint lastStart;
  fml::TimePoint lastTarget;
  XCTestExpectation* predictedCallback =
      [self expectationWithDescription:@"predicted callback fires"];
  auto callback = [&](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {
    callbackCount++;
    lastStart = recorder->GetVsyncStartTime();
    lastTarget = recorder->GetVsyncTargetTime();
    if (callbackCount == 2) {
      [predictedCallback fulfill];
    }
  };

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  // Keep this test on the non-conservative path.
  [vsyncClient setMaxRefreshRate:60.0];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  // Stub display link timestamps so onDisplayLink records a past vsync
  // interval. With this setup, the predicted phase keeps enough headroom to
  // pass the predicted callback scheduling gate.
  id linkMock = OCMPartialMock(link);
  const CFTimeInterval interval = 1.0 / 60.0;
  const CFTimeInterval delay =
      interval * 3 + 0.001;  // Keep enough deterministic lead-time in phase.
  const CFTimeInterval ts = CACurrentMediaTime() - delay;
  [[[linkMock stub] andReturnValue:@(ts)] timestamp];
  [[[linkMock stub] andReturnValue:@(ts + interval)] targetTimestamp];

  [vsyncClient onDisplayLink:(CADisplayLink*)linkMock];
  XCTAssertEqual(callbackCount, 1);

  // Await should schedule a predicted callback and keep the display link paused.
  [vsyncClient await];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(link.isPaused);

  [self waitForExpectations:@[ predictedCallback ] timeout:1.0];
  XCTAssertEqual(callbackCount, 2);

  const fml::TimePoint now = fml::TimePoint::Now();
  XCTAssertTrue(lastStart <= now);
  XCTAssertTrue(lastTarget > now);

  [linkMock stopMocking];
}

- (void)testAwaitFallsBackToDisplayLinkWhenPredictedCallbackWouldBeTooCloseToTarget {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");

  int callbackCount = 0;
  auto callback = [&](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) { callbackCount++; };

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  // Keep this test on the non-conservative path.
  [vsyncClient setMaxRefreshRate:60.0];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  // Stub timestamps so the predicted phase target is ~0.5ms away. This should
  // fail the headroom gate and force fallback to unpausing the display link.
  id linkMock = OCMPartialMock(link);
  const CFTimeInterval interval = 1.0 / 60.0;
  const CFTimeInterval headroom = 0.0005;  // 0.5ms
  const CFTimeInterval delay = interval * 4 - headroom;
  const CFTimeInterval ts = CACurrentMediaTime() - delay;
  [[[linkMock stub] andReturnValue:@(ts)] timestamp];
  [[[linkMock stub] andReturnValue:@(ts + interval)] targetTimestamp];

  [vsyncClient onDisplayLink:(CADisplayLink*)linkMock];
  XCTAssertEqual(callbackCount, 1);

  [vsyncClient await];
  // No synchronous predicted callback should have happened.
  XCTAssertEqual(callbackCount, 1);
  // Fallback path should unpause the real display link.
  XCTAssertFalse(link.isPaused);

  [linkMock stopMocking];
}

- (void)testAwaitDoesNotSchedulePredictedCallbackWhenPauseAfterVsyncDisabled {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");

  int callbackCount = 0;
  auto callback = [&](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) { callbackCount++; };

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  id linkMock = OCMPartialMock(link);
  const CFTimeInterval interval = 1.0 / 60.0;
  const CFTimeInterval delay = interval * 3 + 0.003;
  const CFTimeInterval ts = CACurrentMediaTime() - delay;
  [[[linkMock stub] andReturnValue:@(ts)] timestamp];
  [[[linkMock stub] andReturnValue:@(ts + interval)] targetTimestamp];

  [vsyncClient onDisplayLink:(CADisplayLink*)linkMock];
  XCTAssertEqual(callbackCount, 1);

  vsyncClient.allowPauseAfterVsync = NO;
  [vsyncClient await];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertFalse(link.isPaused);

  [linkMock stopMocking];
}

- (void)testAwaitUsesConservativePredictionWhenMaxRefreshRateIsHigherThanObservedRate {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");

  int callbackCount = 0;
  XCTestExpectation* predictedCallback =
      [self expectationWithDescription:@"predicted callback fires"];
  auto callback = [&](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {
    callbackCount++;
    if (callbackCount == 2) {
      [predictedCallback fulfill];
    }
  };

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  [vsyncClient setMaxRefreshRate:120.0];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  id linkMock = OCMPartialMock(link);
  const CFTimeInterval interval = 1.0 / 60.0;
  const CFTimeInterval delay =
      interval * 3 + 0.001;  // Leave room for conservative 120Hz prediction.
  const CFTimeInterval ts = CACurrentMediaTime() - delay;
  [[[linkMock stub] andReturnValue:@(ts)] timestamp];
  [[[linkMock stub] andReturnValue:@(ts + interval)] targetTimestamp];

  [vsyncClient onDisplayLink:(CADisplayLink*)linkMock];
  XCTAssertEqual(callbackCount, 1);

  [vsyncClient await];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(link.isPaused);

  [self waitForExpectations:@[ predictedCallback ] timeout:1.0];
  XCTAssertEqual(callbackCount, 2);

  [linkMock stopMocking];
}

- (void)testAwaitDoesNotSchedulePredictedCallbackTwiceInSamePredictedPhase {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");

  int callbackCount = 0;
  XCTestExpectation* predictedCallback =
      [self expectationWithDescription:@"single predicted callback fires"];
  auto callback = [&](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {
    callbackCount++;
    if (callbackCount == 2) {
      [predictedCallback fulfill];
    }
  };

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  id linkMock = OCMPartialMock(link);
  const CFTimeInterval interval = 1.0 / 60.0;
  const CFTimeInterval delay =
      interval * 3 + 0.001;  // Keep enough deterministic lead-time in phase.
  const CFTimeInterval ts = CACurrentMediaTime() - delay;
  [[[linkMock stub] andReturnValue:@(ts)] timestamp];
  [[[linkMock stub] andReturnValue:@(ts + interval)] targetTimestamp];

  [vsyncClient onDisplayLink:(CADisplayLink*)linkMock];
  XCTAssertEqual(callbackCount, 1);

  // First await schedules one predicted callback.
  [vsyncClient await];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(link.isPaused);

  // Second await in the same phase should not schedule a duplicate callback.
  [vsyncClient await];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(link.isPaused);

  [self waitForExpectations:@[ predictedCallback ] timeout:1.0];
  XCTAssertEqual(callbackCount, 2);

  [linkMock stopMocking];
}

- (void)testAwaitFallsBackToDisplayLinkWhenNoCachedVsyncAfterInvalidation {
  auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");

  int callbackCount = 0;
  auto callback = [&](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) { callbackCount++; };

  VSyncClient* vsyncClient = [[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                            callback:callback];
  CADisplayLink* link = [vsyncClient getDisplayLink];
  XCTAssertTrue(link.isPaused);

  id linkMock = OCMPartialMock(link);
  const CFTimeInterval interval = 1.0 / 60.0;
  const CFTimeInterval delay = interval * 3 + 0.003;
  const CFTimeInterval ts = CACurrentMediaTime() - delay;
  [[[linkMock stub] andReturnValue:@(ts)] timestamp];
  [[[linkMock stub] andReturnValue:@(ts + interval)] targetTimestamp];

  [vsyncClient onDisplayLink:(CADisplayLink*)linkMock];
  XCTAssertEqual(callbackCount, 1);
  [linkMock stopMocking];

  [vsyncClient invalidate];
  [vsyncClient await];
  // No synchronous predicted callback should fire after cache reset/invalidation.
  XCTAssertEqual(callbackCount, 1);
}

- (void)testReleasesLinkOnInvalidation {
  __weak CADisplayLink* weakLink;
  @autoreleasepool {
    auto thread_task_runner = CreateNewThread("VsyncWaiterIosTest");
    VSyncClient* vsyncClient = [[VSyncClient alloc]
        initWithTaskRunner:thread_task_runner
                  callback:[](std::unique_ptr<flutter::FrameTimingsRecorder> recorder) {}];

    weakLink = [vsyncClient getDisplayLink];
    XCTAssertNotNil(weakLink);
    [vsyncClient invalidate];
  }
  // VSyncClient has released the CADisplayLink.
  XCTAssertNil(weakLink);
}

@end
