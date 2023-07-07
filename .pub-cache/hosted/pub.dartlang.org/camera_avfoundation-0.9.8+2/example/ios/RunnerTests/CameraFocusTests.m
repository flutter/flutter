// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import XCTest;
@import AVFoundation;
#import <OCMock/OCMock.h>

@interface CameraFocusTests : XCTestCase
@property(readonly, nonatomic) FLTCam *camera;
@property(readonly, nonatomic) id mockDevice;
@property(readonly, nonatomic) id mockUIDevice;
@end

@implementation CameraFocusTests

- (void)setUp {
  _camera = [[FLTCam alloc] init];
  _mockDevice = OCMClassMock([AVCaptureDevice class]);
  _mockUIDevice = OCMPartialMock([UIDevice currentDevice]);
}

- (void)tearDown {
  [_mockDevice stopMocking];
  [_mockUIDevice stopMocking];
}

- (void)testAutoFocusWithContinuousModeSupported_ShouldSetContinuousAutoFocus {
  // AVCaptureFocusModeContinuousAutoFocus is supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]).andReturn(true);
  // AVCaptureFocusModeContinuousAutoFocus is supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]).andReturn(true);

  // Don't expect setFocusMode:AVCaptureFocusModeAutoFocus
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeAutoFocus];

  // Run test
  [_camera applyFocusMode:FLTFocusModeAuto onDevice:_mockDevice];

  // Expect setFocusMode:AVCaptureFocusModeContinuousAutoFocus
  OCMVerify([_mockDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus]);
}

- (void)testAutoFocusWithContinuousModeNotSupported_ShouldSetAutoFocus {
  // AVCaptureFocusModeContinuousAutoFocus is not supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
      .andReturn(false);
  // AVCaptureFocusModeContinuousAutoFocus is supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]).andReturn(true);

  // Don't expect setFocusMode:AVCaptureFocusModeContinuousAutoFocus
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];

  // Run test
  [_camera applyFocusMode:FLTFocusModeAuto onDevice:_mockDevice];

  // Expect setFocusMode:AVCaptureFocusModeAutoFocus
  OCMVerify([_mockDevice setFocusMode:AVCaptureFocusModeAutoFocus]);
}

- (void)testAutoFocusWithNoModeSupported_ShouldSetNothing {
  // AVCaptureFocusModeContinuousAutoFocus is not supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
      .andReturn(false);
  // AVCaptureFocusModeContinuousAutoFocus is not supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]).andReturn(false);

  // Don't expect any setFocus
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeAutoFocus];

  // Run test
  [_camera applyFocusMode:FLTFocusModeAuto onDevice:_mockDevice];
}

- (void)testLockedFocusWithModeSupported_ShouldSetModeAutoFocus {
  // AVCaptureFocusModeContinuousAutoFocus is supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]).andReturn(true);
  // AVCaptureFocusModeContinuousAutoFocus is supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]).andReturn(true);

  // Don't expect any setFocus
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];

  // Run test
  [_camera applyFocusMode:FLTFocusModeLocked onDevice:_mockDevice];

  // Expect setFocusMode:AVCaptureFocusModeAutoFocus
  OCMVerify([_mockDevice setFocusMode:AVCaptureFocusModeAutoFocus]);
}

- (void)testLockedFocusWithModeNotSupported_ShouldSetNothing {
  // AVCaptureFocusModeContinuousAutoFocus is supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]).andReturn(true);
  // AVCaptureFocusModeContinuousAutoFocus is not supported
  OCMStub([_mockDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]).andReturn(false);

  // Don't expect any setFocus
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
  [[_mockDevice reject] setFocusMode:AVCaptureFocusModeAutoFocus];

  // Run test
  [_camera applyFocusMode:FLTFocusModeLocked onDevice:_mockDevice];
}

- (void)testSetFocusPointWithResult_SetsFocusPointOfInterest {
  // UI is currently in landscape left orientation
  OCMStub([(UIDevice *)_mockUIDevice orientation]).andReturn(UIDeviceOrientationLandscapeLeft);
  // Focus point of interest is supported
  OCMStub([_mockDevice isFocusPointOfInterestSupported]).andReturn(true);
  // Set mock device as the current capture device
  [_camera setValue:_mockDevice forKey:@"captureDevice"];

  // Run test
  [_camera setFocusPointWithResult:[[FLTThreadSafeFlutterResult alloc]
                                       initWithResult:^(id _Nullable result){
                                       }]
                                 x:1
                                 y:1];

  // Verify the focus point of interest has been set
  OCMVerify([_mockDevice setFocusPointOfInterest:CGPointMake(1, 1)]);
}

@end
