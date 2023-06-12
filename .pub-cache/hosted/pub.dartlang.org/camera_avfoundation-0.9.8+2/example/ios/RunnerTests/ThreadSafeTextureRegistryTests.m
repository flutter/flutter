// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import XCTest;
#import <OCMock/OCMock.h>

@interface ThreadSafeTextureRegistryTests : XCTestCase
@end

@implementation ThreadSafeTextureRegistryTests

- (void)testShouldStayOnMainThreadIfCalledFromMainThread {
  NSObject<FlutterTextureRegistry> *mockTextureRegistry =
      OCMProtocolMock(@protocol(FlutterTextureRegistry));
  FLTThreadSafeTextureRegistry *threadSafeTextureRegistry =
      [[FLTThreadSafeTextureRegistry alloc] initWithTextureRegistry:mockTextureRegistry];

  XCTestExpectation *registerTextureExpectation =
      [self expectationWithDescription:@"registerTexture must be called on the main thread"];
  XCTestExpectation *unregisterTextureExpectation =
      [self expectationWithDescription:@"unregisterTexture must be called on the main thread"];
  XCTestExpectation *textureFrameAvailableExpectation =
      [self expectationWithDescription:@"textureFrameAvailable must be called on the main thread"];
  XCTestExpectation *registerTextureCompletionExpectation =
      [self expectationWithDescription:
                @"registerTexture's completion block must be called on the main thread"];

  OCMStub([mockTextureRegistry registerTexture:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    if (NSThread.isMainThread) {
      [registerTextureExpectation fulfill];
    }
  });

  OCMStub([mockTextureRegistry unregisterTexture:0]).andDo(^(NSInvocation *invocation) {
    if (NSThread.isMainThread) {
      [unregisterTextureExpectation fulfill];
    }
  });

  OCMStub([mockTextureRegistry textureFrameAvailable:0]).andDo(^(NSInvocation *invocation) {
    if (NSThread.isMainThread) {
      [textureFrameAvailableExpectation fulfill];
    }
  });

  NSObject<FlutterTexture> *anyTexture = OCMProtocolMock(@protocol(FlutterTexture));
  [threadSafeTextureRegistry registerTexture:anyTexture
                                  completion:^(int64_t textureId) {
                                    if (NSThread.isMainThread) {
                                      [registerTextureCompletionExpectation fulfill];
                                    }
                                  }];
  [threadSafeTextureRegistry textureFrameAvailable:0];
  [threadSafeTextureRegistry unregisterTexture:0];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testShouldDispatchToMainThreadIfCalledFromBackgroundThread {
  NSObject<FlutterTextureRegistry> *mockTextureRegistry =
      OCMProtocolMock(@protocol(FlutterTextureRegistry));
  FLTThreadSafeTextureRegistry *threadSafeTextureRegistry =
      [[FLTThreadSafeTextureRegistry alloc] initWithTextureRegistry:mockTextureRegistry];

  XCTestExpectation *registerTextureExpectation =
      [self expectationWithDescription:@"registerTexture must be called on the main thread"];
  XCTestExpectation *unregisterTextureExpectation =
      [self expectationWithDescription:@"unregisterTexture must be called on the main thread"];
  XCTestExpectation *textureFrameAvailableExpectation =
      [self expectationWithDescription:@"textureFrameAvailable must be called on the main thread"];
  XCTestExpectation *registerTextureCompletionExpectation =
      [self expectationWithDescription:
                @"registerTexture's completion block must be called on the main thread"];

  OCMStub([mockTextureRegistry registerTexture:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    if (NSThread.isMainThread) {
      [registerTextureExpectation fulfill];
    }
  });

  OCMStub([mockTextureRegistry unregisterTexture:0]).andDo(^(NSInvocation *invocation) {
    if (NSThread.isMainThread) {
      [unregisterTextureExpectation fulfill];
    }
  });

  OCMStub([mockTextureRegistry textureFrameAvailable:0]).andDo(^(NSInvocation *invocation) {
    if (NSThread.isMainThread) {
      [textureFrameAvailableExpectation fulfill];
    }
  });

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSObject<FlutterTexture> *anyTexture = OCMProtocolMock(@protocol(FlutterTexture));
    [threadSafeTextureRegistry registerTexture:anyTexture
                                    completion:^(int64_t textureId) {
                                      if (NSThread.isMainThread) {
                                        [registerTextureCompletionExpectation fulfill];
                                      }
                                    }];
    [threadSafeTextureRegistry textureFrameAvailable:0];
    [threadSafeTextureRegistry unregisterTexture:0];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
