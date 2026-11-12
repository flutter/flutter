// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

FLUTTER_ASSERT_ARC

// This file is compiled as Obj-C rather than Obj-C++.
// It fails to compile if `FlutterPlatformViewsController.h` or `FlutterPlatformViews_Internal.h`
// uses a C++ type or includes a C++ header.
@interface FlutterPlatformViewsControllerObjCTest : XCTestCase
@end

@implementation FlutterPlatformViewsControllerObjCTest

- (void)testCanCreateControllerFromObjC {
  FlutterPlatformViewsController* controller = [[FlutterPlatformViewsController alloc] init];
  XCTAssertNotNil(controller);
}

@end
