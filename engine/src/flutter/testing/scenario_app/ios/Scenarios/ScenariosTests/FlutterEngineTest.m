// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface FlutterEngineTest : XCTestCase
@end

@implementation FlutterEngineTest

- (void)testIsolateId {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  XCTAssertNil(engine.isolateId);
  [self keyValueObservingExpectationForObject:engine keyPath:@"isolateId" handler:nil];

  XCTAssertTrue([engine runWithEntrypoint:nil]);

  [self waitForExpectationsWithTimeout:30.0 handler:nil];

  XCTAssertNotNil(engine.isolateId);
  XCTAssertTrue([engine.isolateId hasPrefix:@"isolates/"]);

  [engine destroyContext];

  XCTAssertNil(engine.isolateId);
}

- (void)testChannelSetup {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  XCTAssertNil(engine.navigationChannel);
  XCTAssertNil(engine.platformChannel);
  XCTAssertNil(engine.lifecycleChannel);

  XCTAssertTrue([engine run]);

  XCTAssertNotNil(engine.navigationChannel);
  XCTAssertNotNil(engine.platformChannel);
  XCTAssertNotNil(engine.lifecycleChannel);

  [engine destroyContext];

  XCTAssertNil(engine.navigationChannel);
  XCTAssertNil(engine.platformChannel);
  XCTAssertNil(engine.lifecycleChannel);
}

@end
