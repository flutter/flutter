// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Test.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_NOT_ARC

@interface FlutterEngineTest_mrc : XCTestCase
@end

@implementation FlutterEngineTest_mrc

- (void)setUp {
}

- (void)tearDown {
}

- (void)testSpawnsShareGpuContext {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
  [engine run];
  FlutterEngine* spawn = [engine spawnWithEntrypoint:nil libraryURI:nil];
  XCTAssertNotNil(spawn);
  XCTAssertTrue([engine iosPlatformView] != nullptr);
  XCTAssertTrue([spawn iosPlatformView] != nullptr);
  XCTAssertEqual([engine iosPlatformView]->GetIosContext(),
                 [spawn iosPlatformView]->GetIosContext());
}

@end
