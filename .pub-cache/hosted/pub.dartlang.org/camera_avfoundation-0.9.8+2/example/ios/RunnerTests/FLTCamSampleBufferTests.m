// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import AVFoundation;
@import XCTest;
#import <OCMock/OCMock.h>
#import "CameraTestUtils.h"

/// Includes test cases related to sample buffer handling for FLTCam class.
@interface FLTCamSampleBufferTests : XCTestCase

@end

@implementation FLTCamSampleBufferTests

- (void)testSampleBufferCallbackQueueMustBeCaptureSessionQueue {
  dispatch_queue_t captureSessionQueue = dispatch_queue_create("testing", NULL);
  FLTCam *cam = FLTCreateCamWithCaptureSessionQueue(captureSessionQueue);
  XCTAssertEqual(captureSessionQueue, cam.captureVideoOutput.sampleBufferCallbackQueue,
                 @"Sample buffer callback queue must be the capture session queue.");
}

- (void)testCopyPixelBuffer {
  FLTCam *cam = FLTCreateCamWithCaptureSessionQueue(dispatch_queue_create("test", NULL));
  CMSampleBufferRef capturedSampleBuffer = FLTCreateTestSampleBuffer();
  CVPixelBufferRef capturedPixelBuffer = CMSampleBufferGetImageBuffer(capturedSampleBuffer);
  // Mimic sample buffer callback when captured a new video sample
  [cam captureOutput:cam.captureVideoOutput
      didOutputSampleBuffer:capturedSampleBuffer
             fromConnection:OCMClassMock([AVCaptureConnection class])];
  CVPixelBufferRef deliveriedPixelBuffer = [cam copyPixelBuffer];
  XCTAssertEqual(deliveriedPixelBuffer, capturedPixelBuffer,
                 @"FLTCam must deliver the latest captured pixel buffer to copyPixelBuffer API.");
  CFRelease(capturedSampleBuffer);
  CFRelease(deliveriedPixelBuffer);
}

@end
