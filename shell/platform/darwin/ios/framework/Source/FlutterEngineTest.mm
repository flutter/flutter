// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

@interface FlutteEngineTest : XCTestCase
@end

@implementation FlutteEngineTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testCreate {
  id project = OCMClassMock([FlutterDartProject class]);
  FlutterEngine* engine = [[[FlutterEngine alloc] initWithName:@"foobar"
                                                       project:project] autorelease];
  XCTAssertNotNil(engine);
}

@end
