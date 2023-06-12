// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import XCTest;

@interface CameraCaptureSessionQueueRaceConditionTests : XCTestCase
@end

@implementation CameraCaptureSessionQueueRaceConditionTests

- (void)testFixForCaptureSessionQueueNullPointerCrashDueToRaceCondition {
  CameraPlugin *camera = [[CameraPlugin alloc] initWithRegistry:nil messenger:nil];

  XCTestExpectation *disposeExpectation =
      [self expectationWithDescription:@"dispose's result block must be called"];
  XCTestExpectation *createExpectation =
      [self expectationWithDescription:@"create's result block must be called"];
  FlutterMethodCall *disposeCall = [FlutterMethodCall methodCallWithMethodName:@"dispose"
                                                                     arguments:nil];
  FlutterMethodCall *createCall = [FlutterMethodCall
      methodCallWithMethodName:@"create"
                     arguments:@{@"resolutionPreset" : @"medium", @"enableAudio" : @(1)}];
  // Mimic a dispose call followed by a create call, which can be triggered by slightly dragging the
  // home bar, causing the app to be inactive, and immediately regain active.
  [camera handleMethodCall:disposeCall
                    result:^(id _Nullable result) {
                      [disposeExpectation fulfill];
                    }];
  [camera createCameraOnSessionQueueWithCreateMethodCall:createCall
                                                  result:[[FLTThreadSafeFlutterResult alloc]
                                                             initWithResult:^(id _Nullable result) {
                                                               [createExpectation fulfill];
                                                             }]];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  // `captureSessionQueue` must not be nil after `create` call. Otherwise a nil
  // `captureSessionQueue` passed into `AVCaptureVideoDataOutput::setSampleBufferDelegate:queue:`
  // API will cause a crash.
  XCTAssertNotNil(camera.captureSessionQueue,
                  @"captureSessionQueue must not be nil after create method. ");
}

@end
