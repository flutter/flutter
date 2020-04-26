// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(dnfield): This belongs in the engine repo.
#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>

@interface ViewControllerRelease : XCTestCase
@end


@implementation ViewControllerRelease

- (void)testReleaseFlutterViewController {
 __weak FlutterEngine* weakEngine;
 @autoreleasepool {
   FlutterViewController* viewController = [[FlutterViewController alloc]
   init];
   weakEngine = viewController.engine;
   [viewController viewWillAppear:NO];
   [viewController viewDidDisappear:NO];
 }
 XCTAssertNil(weakEngine, @"Engine failed to release.");
}

@end
