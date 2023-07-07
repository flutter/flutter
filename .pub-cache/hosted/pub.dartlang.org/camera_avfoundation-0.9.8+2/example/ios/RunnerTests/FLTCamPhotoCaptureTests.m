// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import AVFoundation;
@import XCTest;
#import <OCMock/OCMock.h>
#import "CameraTestUtils.h"

/// Includes test cases related to photo capture operations for FLTCam class.
@interface FLTCamPhotoCaptureTests : XCTestCase

@end

@implementation FLTCamPhotoCaptureTests

- (void)testCaptureToFile_mustReportErrorToResultIfSavePhotoDelegateCompletionsWithError {
  XCTestExpectation *errorExpectation =
      [self expectationWithDescription:
                @"Must send error to result if save photo delegate completes with error."];

  dispatch_queue_t captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
  dispatch_queue_set_specific(captureSessionQueue, FLTCaptureSessionQueueSpecific,
                              (void *)FLTCaptureSessionQueueSpecific, NULL);
  FLTCam *cam = FLTCreateCamWithCaptureSessionQueue(captureSessionQueue);
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
  id mockSettings = OCMClassMock([AVCapturePhotoSettings class]);
  OCMStub([mockSettings photoSettings]).andReturn(settings);

  NSError *error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
  id mockResult = OCMClassMock([FLTThreadSafeFlutterResult class]);
  OCMStub([mockResult sendError:error]).andDo(^(NSInvocation *invocation) {
    [errorExpectation fulfill];
  });

  id mockOutput = OCMClassMock([AVCapturePhotoOutput class]);
  OCMStub([mockOutput capturePhotoWithSettings:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        FLTSavePhotoDelegate *delegate = cam.inProgressSavePhotoDelegates[@(settings.uniqueID)];
        // Completion runs on IO queue.
        dispatch_queue_t ioQueue = dispatch_queue_create("io_queue", NULL);
        dispatch_async(ioQueue, ^{
          delegate.completionHandler(nil, error);
        });
      });
  cam.capturePhotoOutput = mockOutput;

  // `FLTCam::captureToFile` runs on capture session queue.
  dispatch_async(captureSessionQueue, ^{
    [cam captureToFile:mockResult];
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCaptureToFile_mustReportPathToResultIfSavePhotoDelegateCompletionsWithPath {
  XCTestExpectation *pathExpectation =
      [self expectationWithDescription:
                @"Must send file path to result if save photo delegate completes with file path."];

  dispatch_queue_t captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
  dispatch_queue_set_specific(captureSessionQueue, FLTCaptureSessionQueueSpecific,
                              (void *)FLTCaptureSessionQueueSpecific, NULL);
  FLTCam *cam = FLTCreateCamWithCaptureSessionQueue(captureSessionQueue);

  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
  id mockSettings = OCMClassMock([AVCapturePhotoSettings class]);
  OCMStub([mockSettings photoSettings]).andReturn(settings);

  NSString *filePath = @"test";
  id mockResult = OCMClassMock([FLTThreadSafeFlutterResult class]);
  OCMStub([mockResult sendSuccessWithData:filePath]).andDo(^(NSInvocation *invocation) {
    [pathExpectation fulfill];
  });

  id mockOutput = OCMClassMock([AVCapturePhotoOutput class]);
  OCMStub([mockOutput capturePhotoWithSettings:OCMOCK_ANY delegate:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        FLTSavePhotoDelegate *delegate = cam.inProgressSavePhotoDelegates[@(settings.uniqueID)];
        // Completion runs on IO queue.
        dispatch_queue_t ioQueue = dispatch_queue_create("io_queue", NULL);
        dispatch_async(ioQueue, ^{
          delegate.completionHandler(filePath, nil);
        });
      });
  cam.capturePhotoOutput = mockOutput;

  // `FLTCam::captureToFile` runs on capture session queue.
  dispatch_async(captureSessionQueue, ^{
    [cam captureToFile:mockResult];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
