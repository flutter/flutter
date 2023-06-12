// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import AVFoundation;
@import XCTest;
#import <OCMock/OCMock.h>

@interface FLTSavePhotoDelegateTests : XCTestCase

@end

@implementation FLTSavePhotoDelegateTests

- (void)testHandlePhotoCaptureResult_mustCompleteWithErrorIfFailedToCapture {
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"Must complete with error if failed to capture photo."];

  NSError *captureError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
  dispatch_queue_t ioQueue = dispatch_queue_create("test", NULL);
  FLTSavePhotoDelegate *delegate = [[FLTSavePhotoDelegate alloc]
           initWithPath:@"test"
                ioQueue:ioQueue
      completionHandler:^(NSString *_Nullable path, NSError *_Nullable error) {
        XCTAssertEqualObjects(captureError, error);
        XCTAssertNil(path);
        [completionExpectation fulfill];
      }];

  [delegate handlePhotoCaptureResultWithError:captureError
                            photoDataProvider:^NSData * {
                              return nil;
                            }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHandlePhotoCaptureResult_mustCompleteWithErrorIfFailedToWrite {
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"Must complete with error if failed to write file."];
  dispatch_queue_t ioQueue = dispatch_queue_create("test", NULL);

  NSError *ioError = [NSError errorWithDomain:@"IOError"
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey : @"Localized IO Error"}];
  FLTSavePhotoDelegate *delegate = [[FLTSavePhotoDelegate alloc]
           initWithPath:@"test"
                ioQueue:ioQueue
      completionHandler:^(NSString *_Nullable path, NSError *_Nullable error) {
        XCTAssertEqualObjects(ioError, error);
        XCTAssertNil(path);
        [completionExpectation fulfill];
      }];

  // Do not use OCMClassMock for NSData because some XCTest APIs uses NSData (e.g.
  // `XCTRunnerIDESession::logDebugMessage:`) on a private queue.
  id mockData = OCMPartialMock([NSData data]);
  OCMStub([mockData writeToFile:OCMOCK_ANY
                        options:NSDataWritingAtomic
                          error:[OCMArg setTo:ioError]])
      .andReturn(NO);
  [delegate handlePhotoCaptureResultWithError:nil
                            photoDataProvider:^NSData * {
                              return mockData;
                            }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHandlePhotoCaptureResult_mustCompleteWithFilePathIfSuccessToWrite {
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"Must complete with file path if success to write file."];

  dispatch_queue_t ioQueue = dispatch_queue_create("test", NULL);
  NSString *filePath = @"test";
  FLTSavePhotoDelegate *delegate = [[FLTSavePhotoDelegate alloc]
           initWithPath:filePath
                ioQueue:ioQueue
      completionHandler:^(NSString *_Nullable path, NSError *_Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(filePath, path);
        [completionExpectation fulfill];
      }];

  // Do not use OCMClassMock for NSData because some XCTest APIs uses NSData (e.g.
  // `XCTRunnerIDESession::logDebugMessage:`) on a private queue.
  id mockData = OCMPartialMock([NSData data]);
  OCMStub([mockData writeToFile:filePath options:NSDataWritingAtomic error:[OCMArg setTo:nil]])
      .andReturn(YES);

  [delegate handlePhotoCaptureResultWithError:nil
                            photoDataProvider:^NSData * {
                              return mockData;
                            }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHandlePhotoCaptureResult_bothProvideDataAndSaveFileMustRunOnIOQueue {
  XCTestExpectation *dataProviderQueueExpectation =
      [self expectationWithDescription:@"Data provider must run on io queue."];
  XCTestExpectation *writeFileQueueExpectation =
      [self expectationWithDescription:@"File writing must run on io queue"];
  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"Must complete with file path if success to write file."];

  dispatch_queue_t ioQueue = dispatch_queue_create("test", NULL);
  const char *ioQueueSpecific = "io_queue_specific";
  dispatch_queue_set_specific(ioQueue, ioQueueSpecific, (void *)ioQueueSpecific, NULL);

  // Do not use OCMClassMock for NSData because some XCTest APIs uses NSData (e.g.
  // `XCTRunnerIDESession::logDebugMessage:`) on a private queue.
  id mockData = OCMPartialMock([NSData data]);
  OCMStub([mockData writeToFile:OCMOCK_ANY options:NSDataWritingAtomic error:[OCMArg setTo:nil]])
      .andDo(^(NSInvocation *invocation) {
        if (dispatch_get_specific(ioQueueSpecific)) {
          [writeFileQueueExpectation fulfill];
        }
      })
      .andReturn(YES);

  NSString *filePath = @"test";
  FLTSavePhotoDelegate *delegate = [[FLTSavePhotoDelegate alloc]
           initWithPath:filePath
                ioQueue:ioQueue
      completionHandler:^(NSString *_Nullable path, NSError *_Nullable error) {
        [completionExpectation fulfill];
      }];

  [delegate handlePhotoCaptureResultWithError:nil
                            photoDataProvider:^NSData * {
                              if (dispatch_get_specific(ioQueueSpecific)) {
                                [dataProviderQueueExpectation fulfill];
                              }
                              return mockData;
                            }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
