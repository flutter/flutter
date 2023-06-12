// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import XCTest;
@import Flutter;

#import <OCMock/OCMock.h>

@interface CameraOrientationTests : XCTestCase
@end

@implementation CameraOrientationTests

- (void)testOrientationNotifications {
  id mockMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  CameraPlugin *cameraPlugin = [[CameraPlugin alloc] initWithRegistry:nil messenger:mockMessenger];

  [mockMessenger setExpectationOrderMatters:YES];

  [self rotate:UIDeviceOrientationPortraitUpsideDown
      expectedChannelOrientation:@"portraitDown"
                    cameraPlugin:cameraPlugin
                       messenger:mockMessenger];
  [self rotate:UIDeviceOrientationPortrait
      expectedChannelOrientation:@"portraitUp"
                    cameraPlugin:cameraPlugin
                       messenger:mockMessenger];
  [self rotate:UIDeviceOrientationLandscapeRight
      expectedChannelOrientation:@"landscapeLeft"
                    cameraPlugin:cameraPlugin
                       messenger:mockMessenger];
  [self rotate:UIDeviceOrientationLandscapeLeft
      expectedChannelOrientation:@"landscapeRight"
                    cameraPlugin:cameraPlugin
                       messenger:mockMessenger];

  OCMReject([mockMessenger sendOnChannel:[OCMArg any] message:[OCMArg any]]);

  // No notification when flat.
  [cameraPlugin
      orientationChanged:[self createMockNotificationForOrientation:UIDeviceOrientationFaceUp]];
  // No notification when facedown.
  [cameraPlugin
      orientationChanged:[self createMockNotificationForOrientation:UIDeviceOrientationFaceDown]];

  OCMVerifyAll(mockMessenger);
}

- (void)testOrientationUpdateMustBeOnCaptureSessionQueue {
  XCTestExpectation *queueExpectation = [self
      expectationWithDescription:@"Orientation update must happen on the capture session queue"];

  CameraPlugin *camera = [[CameraPlugin alloc] initWithRegistry:nil messenger:nil];
  const char *captureSessionQueueSpecific = "capture_session_queue";
  dispatch_queue_set_specific(camera.captureSessionQueue, captureSessionQueueSpecific,
                              (void *)captureSessionQueueSpecific, NULL);
  FLTCam *mockCam = OCMClassMock([FLTCam class]);
  camera.camera = mockCam;
  OCMStub([mockCam setDeviceOrientation:UIDeviceOrientationLandscapeLeft])
      .andDo(^(NSInvocation *invocation) {
        if (dispatch_get_specific(captureSessionQueueSpecific)) {
          [queueExpectation fulfill];
        }
      });

  [camera orientationChanged:
              [self createMockNotificationForOrientation:UIDeviceOrientationLandscapeLeft]];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)rotate:(UIDeviceOrientation)deviceOrientation
    expectedChannelOrientation:(NSString *)channelOrientation
                  cameraPlugin:(CameraPlugin *)cameraPlugin
                     messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
  XCTestExpectation *orientationExpectation = [self expectationWithDescription:channelOrientation];

  OCMExpect([messenger
      sendOnChannel:[OCMArg any]
            message:[OCMArg checkWithBlock:^BOOL(NSData *data) {
              NSObject<FlutterMethodCodec> *codec = [FlutterStandardMethodCodec sharedInstance];
              FlutterMethodCall *methodCall = [codec decodeMethodCall:data];
              [orientationExpectation fulfill];
              return
                  [methodCall.method isEqualToString:@"orientation_changed"] &&
                  [methodCall.arguments isEqualToDictionary:@{@"orientation" : channelOrientation}];
            }]]);

  [cameraPlugin orientationChanged:[self createMockNotificationForOrientation:deviceOrientation]];
  [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

- (NSNotification *)createMockNotificationForOrientation:(UIDeviceOrientation)deviceOrientation {
  UIDevice *mockDevice = OCMClassMock([UIDevice class]);
  OCMStub([mockDevice orientation]).andReturn(deviceOrientation);

  return [NSNotification notificationWithName:@"orientation_test" object:mockDevice];
}

@end
