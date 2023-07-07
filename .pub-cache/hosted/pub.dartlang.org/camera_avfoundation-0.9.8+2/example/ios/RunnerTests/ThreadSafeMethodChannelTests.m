// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import XCTest;
#import <OCMock/OCMock.h>

@interface ThreadSafeMethodChannelTests : XCTestCase
@end

@implementation ThreadSafeMethodChannelTests

- (void)testInvokeMethod_shouldStayOnMainThreadIfCalledFromMainThread {
  FlutterMethodChannel *mockMethodChannel = OCMClassMock([FlutterMethodChannel class]);
  FLTThreadSafeMethodChannel *threadSafeMethodChannel =
      [[FLTThreadSafeMethodChannel alloc] initWithMethodChannel:mockMethodChannel];

  XCTestExpectation *mainThreadExpectation =
      [self expectationWithDescription:@"invokeMethod must be called on the main thread"];

  OCMStub([mockMethodChannel invokeMethod:[OCMArg any] arguments:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        if (NSThread.isMainThread) {
          [mainThreadExpectation fulfill];
        }
      });

  [threadSafeMethodChannel invokeMethod:@"foo" arguments:nil];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInvokeMethod__shouldDispatchToMainThreadIfCalledFromBackgroundThread {
  FlutterMethodChannel *mockMethodChannel = OCMClassMock([FlutterMethodChannel class]);
  FLTThreadSafeMethodChannel *threadSafeMethodChannel =
      [[FLTThreadSafeMethodChannel alloc] initWithMethodChannel:mockMethodChannel];

  XCTestExpectation *mainThreadExpectation =
      [self expectationWithDescription:@"invokeMethod must be called on the main thread"];

  OCMStub([mockMethodChannel invokeMethod:[OCMArg any] arguments:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        if (NSThread.isMainThread) {
          [mainThreadExpectation fulfill];
        }
      });

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [threadSafeMethodChannel invokeMethod:@"foo" arguments:nil];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
