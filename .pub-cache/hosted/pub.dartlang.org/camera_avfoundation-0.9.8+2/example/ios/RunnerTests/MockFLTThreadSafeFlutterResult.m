// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import XCTest;

#import "MockFLTThreadSafeFlutterResult.h"

@implementation MockFLTThreadSafeFlutterResult

- (instancetype)initWithExpectation:(XCTestExpectation *)expectation {
  self = [super init];
  _expectation = expectation;
  return self;
}

- (void)sendSuccessWithData:(id)data {
  self.receivedResult = data;
  [self.expectation fulfill];
}

- (void)sendSuccess {
  self.receivedResult = nil;
  [self.expectation fulfill];
}
@end
