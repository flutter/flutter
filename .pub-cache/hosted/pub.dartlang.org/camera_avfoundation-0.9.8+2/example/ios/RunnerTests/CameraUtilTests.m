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

- (CGPoint)getCGPointForCoordsWithOrientation:(UIDeviceOrientation)orientation
                                            x:(double)x
                                            y:(double)y;

@end

@interface CameraUtilTests : XCTestCase
@property(readonly, nonatomic) FLTCam *camera;

@end

@implementation CameraUtilTests

- (void)setUp {
  _camera = [[FLTCam alloc] init];
}

- (void)testGetCGPointForCoordsWithOrientation_ShouldRotateCoords {
  CGPoint point;
  point = [_camera getCGPointForCoordsWithOrientation:UIDeviceOrientationLandscapeLeft x:1 y:1];
  XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(1, 1)),
                @"Resulting coordinates are invalid.");
  point = [_camera getCGPointForCoordsWithOrientation:UIDeviceOrientationPortrait x:0 y:1];
  XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(1, 1)),
                @"Resulting coordinates are invalid.");
  point = [_camera getCGPointForCoordsWithOrientation:UIDeviceOrientationLandscapeRight x:0 y:0];
  XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(1, 1)),
                @"Resulting coordinates are invalid.");
  point = [_camera getCGPointForCoordsWithOrientation:UIDeviceOrientationPortraitUpsideDown
                                                    x:1
                                                    y:0];
  XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(1, 1)),
                @"Resulting coordinates are invalid.");
}

@end
