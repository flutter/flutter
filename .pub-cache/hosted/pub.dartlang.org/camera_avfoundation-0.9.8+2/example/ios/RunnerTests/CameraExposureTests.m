// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import XCTest;
@import AVFoundation;
#import <OCMock/OCMock.h>

@interface FLTCam : NSObject <FlutterTexture,
                              AVCaptureVideoDataOutputSampleBufferDelegate,
                              AVCaptureAudioDataOutputSampleBufferDelegate>

- (void)setExposurePointWithResult:(FlutterResult)result x:(double)x y:(double)y;
@end

@interface CameraExposureTests : XCTestCase
@property(readonly, nonatomic) FLTCam *camera;
@property(readonly, nonatomic) id mockDevice;
@property(readonly, nonatomic) id mockUIDevice;
@end

@implementation CameraExposureTests

- (void)setUp {
  _camera = [[FLTCam alloc] init];
  _mockDevice = OCMClassMock([AVCaptureDevice class]);
  _mockUIDevice = OCMPartialMock([UIDevice currentDevice]);
}

- (void)tearDown {
  [_mockDevice stopMocking];
  [_mockUIDevice stopMocking];
}

- (void)testSetExpsourePointWithResult_SetsExposurePointOfInterest {
  // UI is currently in landscape left orientation
  OCMStub([(UIDevice *)_mockUIDevice orientation]).andReturn(UIDeviceOrientationLandscapeLeft);
  // Exposure point of interest is supported
  OCMStub([_mockDevice isExposurePointOfInterestSupported]).andReturn(true);
  // Set mock device as the current capture device
  [_camera setValue:_mockDevice forKey:@"captureDevice"];

  // Run test
  [_camera
      setExposurePointWithResult:^void(id _Nullable result) {
      }
                               x:1
                               y:1];

  // Verify the focus point of interest has been set
  OCMVerify([_mockDevice setExposurePointOfInterest:CGPointMake(1, 1)]);
}

@end
