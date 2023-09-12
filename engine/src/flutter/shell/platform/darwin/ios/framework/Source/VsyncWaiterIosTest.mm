// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/thread.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

FLUTTER_ASSERT_NOT_ARC
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
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"])
      .andReturn(@NO);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  VSyncClient* vsyncClient = [[[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                             callback:callback] autorelease];
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
  VSyncClient* vsyncClient = [[[VSyncClient alloc] initWithTaskRunner:thread_task_runner
                                                             callback:callback] autorelease];
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
}

- (void)testRefreshRateUpdatedTo80WhenThraedsMerge {
  auto platform_thread_task_runner = CreateNewThread("Platform");
  auto raster_thread_task_runner = CreateNewThread("Raster");
  auto ui_thread_task_runner = CreateNewThread("UI");
  auto io_thread_task_runner = CreateNewThread("IO");
  auto task_runners =
      flutter::TaskRunners("test", platform_thread_task_runner, raster_thread_task_runner,
                           ui_thread_task_runner, io_thread_task_runner);

  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  [[[mockDisplayLinkManager stub] andReturnValue:@(YES)] maxRefreshRateEnabledOnIPhone];
  auto vsync_waiter = flutter::VsyncWaiterIOS(task_runners);

  fml::scoped_nsobject<VSyncClient> vsyncClient = vsync_waiter.GetVsyncClient();
  CADisplayLink* link = [vsyncClient.get() getDisplayLink];

  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, maxFrameRate / 2, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, maxFrameRate, 0.1);
  }

  const auto merger = fml::RasterThreadMerger::CreateOrShareThreadMerger(
      nullptr, platform_thread_task_runner->GetTaskQueueId(),
      raster_thread_task_runner->GetTaskQueueId());

  merger->MergeWithLease(5);
  vsync_waiter.AwaitVSync();

  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, 80, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, 80, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, 60, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, 80, 0.1);
  }

  merger->UnMergeNowIfLastOne();
  vsync_waiter.AwaitVSync();

  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, maxFrameRate / 2, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, maxFrameRate, 0.1);
  }

  if (@available(iOS 14.0, *)) {
    // Fake response that we are running on Mac.
    id processInfo = [NSProcessInfo processInfo];
    id processInfoPartialMock = OCMPartialMock(processInfo);
    bool iOSAppOnMac = true;
    [OCMStub([processInfoPartialMock isiOSAppOnMac]) andReturnValue:OCMOCK_VALUE(iOSAppOnMac)];

    merger->MergeWithLease(5);
    vsync_waiter.AwaitVSync();

    // On Mac, framerate should be uncapped.
    if (@available(iOS 15.0, *)) {
      XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, maxFrameRate, 0.1);
      XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, maxFrameRate, 0.1);
      XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, maxFrameRate / 2, 0.1);
    } else {
      XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, 80, 0.1);
    }

    merger->UnMergeNowIfLastOne();
    vsync_waiter.AwaitVSync();

    if (@available(iOS 15.0, *)) {
      XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, maxFrameRate, 0.1);
      XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, maxFrameRate, 0.1);
      XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, maxFrameRate / 2, 0.1);
    } else {
      XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, maxFrameRate, 0.1);
    }
  }
}

@end
