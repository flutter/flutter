// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import XCTest;
@import AVFoundation;
#import <OCMock/OCMock.h>
#import "MockFLTThreadSafeFlutterResult.h"

@interface CameraPreviewPauseTests : XCTestCase
@end

@implementation CameraPreviewPauseTests

- (void)testPausePreviewWithResult_shouldPausePreview {
  FLTCam *camera = [[FLTCam alloc] init];
  MockFLTThreadSafeFlutterResult *resultObject = [[MockFLTThreadSafeFlutterResult alloc] init];

  [camera pausePreviewWithResult:resultObject];
  XCTAssertTrue(camera.isPreviewPaused);
}

- (void)testResumePreviewWithResult_shouldResumePreview {
  FLTCam *camera = [[FLTCam alloc] init];
  MockFLTThreadSafeFlutterResult *resultObject = [[MockFLTThreadSafeFlutterResult alloc] init];

  [camera resumePreviewWithResult:resultObject];
  XCTAssertFalse(camera.isPreviewPaused);
}

@end
