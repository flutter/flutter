// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunnerTestHelper.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient+FML.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient+Testing.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

FLUTTER_ASSERT_ARC

@interface FlutterVSyncClientTest : XCTestCase
@property(nonatomic, strong) FlutterFMLTaskRunner* threadTaskRunner;
@end

@implementation FlutterVSyncClientTest

- (void)setUp {
  [super setUp];
  self.threadTaskRunner =
      [FlutterFMLTaskRunnerTestHelper makeTaskRunnerWithLabel:@"VSyncClientTest"];
}

- (void)tearDown {
  self.threadTaskRunner = nil;
  [super tearDown];
}

- (void)testSetAllowPauseAfterVsyncCorrect {
  FlutterVSyncClient* vsyncClient = [[FlutterVSyncClient alloc]
      initWithTaskRunner:self.threadTaskRunner
                callback:^(CFTimeInterval startTime, CFTimeInterval targetTime){
                }];
  CADisplayLink* link = vsyncClient.displayLink;
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
  void (^callback)(CFTimeInterval, CFTimeInterval) =
      ^(CFTimeInterval startTime, CFTimeInterval targetTime) {
      };
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kCADisableMinimumFrameDurationOnPhoneKey])
      .andReturn(@YES);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[FlutterDisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  FlutterVSyncClient* vsyncClient =
      [[FlutterVSyncClient alloc] initWithTaskRunner:self.threadTaskRunner callback:callback];
  CADisplayLink* link = vsyncClient.displayLink;
  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, maxFrameRate, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, maxFrameRate / 2, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, maxFrameRate, 0.1);
  }
}

- (void)testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotOn {
  void (^callback)(CFTimeInterval, CFTimeInterval) =
      ^(CFTimeInterval startTime, CFTimeInterval targetTime) {
      };
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kCADisableMinimumFrameDurationOnPhoneKey])
      .andReturn(@NO);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[FlutterDisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  FlutterVSyncClient* vsyncClient =
      [[FlutterVSyncClient alloc] initWithTaskRunner:self.threadTaskRunner callback:callback];
  CADisplayLink* link = vsyncClient.displayLink;
  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, 0, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, 0, 0.1);
  }
}

- (void)testDoNotSetVariableRefreshRatesIfCADisableMinimumFrameDurationOnPhoneIsNotSet {
  void (^callback)(CFTimeInterval, CFTimeInterval) =
      ^(CFTimeInterval startTime, CFTimeInterval targetTime) {
      };
  id mockDisplayLinkManager = [OCMockObject mockForClass:[FlutterDisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  FlutterVSyncClient* vsyncClient =
      [[FlutterVSyncClient alloc] initWithTaskRunner:self.threadTaskRunner callback:callback];
  CADisplayLink* link = vsyncClient.displayLink;
  if (@available(iOS 15.0, *)) {
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.maximum, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.preferred, 0, 0.1);
    XCTAssertEqualWithAccuracy(link.preferredFrameRateRange.minimum, 0, 0.1);
  } else {
    XCTAssertEqualWithAccuracy(link.preferredFramesPerSecond, 0, 0.1);
  }
}

- (void)testAwaitAndPauseWillWorkCorrectly {
  FlutterVSyncClient* vsyncClient = [[FlutterVSyncClient alloc]
      initWithTaskRunner:self.threadTaskRunner
                callback:^(CFTimeInterval startTime, CFTimeInterval targetTime){
                }];

  CADisplayLink* link = vsyncClient.displayLink;
  XCTAssertTrue(link.isPaused);

  [vsyncClient await];
  XCTAssertFalse(link.isPaused);

  [vsyncClient pause];
  XCTAssertTrue(link.isPaused);
}

- (void)testReleasesLinkOnInvalidation {
  FlutterFMLTaskRunner* threadTaskRunner =
      [FlutterFMLTaskRunnerTestHelper makeTaskRunnerWithLabel:@"FlutterVSyncClientTest"];

  __weak FlutterVSyncClient* weakClient;

  @autoreleasepool {
    XCTestExpectation* vsyncExpectation = [self expectationWithDescription:@"vsync"];

    FlutterVSyncClient* client = [[FlutterVSyncClient alloc]
        initWithTaskRunner:threadTaskRunner
                  callback:^(CFTimeInterval startTime, CFTimeInterval targetTime) {
                    [vsyncExpectation fulfill];
                  }];
    weakClient = client;

    [threadTaskRunner postTask:^{
      [client await];
    }];

    [self waitForExpectations:@[ vsyncExpectation ] timeout:1.0];

    // Invalidate the client. This removes the CADisplayLink from the run loop
    // and breaks the CADisplayLink -> FlutterVSyncClient retain cycle.
    [client invalidate];

    // Let go of the local client pointer.
    client = nil;
  }

  // Force a wait for the background queue to process any pending releases.
  // This ensures the background thread's run loop has drained its autorelease pool.
  XCTestExpectation* backgroundThreadFlushed =
      [self expectationWithDescription:@"Background thread flushed"];

  [threadTaskRunner postTask:^{
    [backgroundThreadFlushed fulfill];
  }];

  [self waitForExpectationsWithTimeout:1.0 handler:nil];

  // The client should be deallocated now that the retain cycle is broken.
  // Note: We do not assert that the CADisplayLink itself is deallocated, as
  // QuartzCore may retain it internally for an unspecified duration after invalidation.
  XCTAssertNil(weakClient);
}

@end
