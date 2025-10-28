// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterLaunchEngine.h"

FLUTTER_ASSERT_ARC;

@interface FlutterLaunchEngineTest : XCTestCase
@end

@implementation FlutterLaunchEngineTest

- (void)testSimple {
  FlutterLaunchEngine* launchEngine = [[FlutterLaunchEngine alloc] init];
  XCTAssertTrue(launchEngine.engine);
  XCTAssertTrue([launchEngine takeEngine]);
  XCTAssertFalse(launchEngine.engine);
}

@end
