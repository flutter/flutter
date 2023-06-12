// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "CameraTestUtils.h"
#import <OCMock/OCMock.h>
@import AVFoundation;

FLTCam *FLTCreateCamWithCaptureSessionQueue(dispatch_queue_t captureSessionQueue) {
  id inputMock = OCMClassMock([AVCaptureDeviceInput class]);
  OCMStub([inputMock deviceInputWithDevice:[OCMArg any] error:[OCMArg setTo:nil]])
      .andReturn(inputMock);

  id sessionMock = OCMClassMock([AVCaptureSession class]);
  OCMStub([sessionMock addInputWithNoConnections:[OCMArg any]]);  // no-op
  OCMStub([sessionMock canSetSessionPreset:[OCMArg any]]).andReturn(YES);

  return [[FLTCam alloc] initWithCameraName:@"camera"
                           resolutionPreset:@"medium"
                                enableAudio:true
                                orientation:UIDeviceOrientationPortrait
                             captureSession:sessionMock
                        captureSessionQueue:captureSessionQueue
                                      error:nil];
}

CMSampleBufferRef FLTCreateTestSampleBuffer(void) {
  CVPixelBufferRef pixelBuffer;
  CVPixelBufferCreate(kCFAllocatorDefault, 100, 100, kCVPixelFormatType_32BGRA, NULL, &pixelBuffer);

  CMFormatDescriptionRef formatDescription;
  CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer,
                                               &formatDescription);

  CMSampleTimingInfo timingInfo = {CMTimeMake(1, 44100), kCMTimeZero, kCMTimeInvalid};

  CMSampleBufferRef sampleBuffer;
  CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, pixelBuffer, formatDescription,
                                           &timingInfo, &sampleBuffer);

  CFRelease(pixelBuffer);
  CFRelease(formatDescription);
  return sampleBuffer;
}
