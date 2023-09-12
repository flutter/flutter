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

@interface FlutterEngineSpy : FlutterEngine
@property(nonatomic) BOOL ensureSemanticsEnabledCalled;
@end

@implementation FlutterEngineSpy

- (void)ensureSemanticsEnabled {
  _ensureSemanticsEnabledCalled = YES;
}

@end

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
  FlutterEngine* spawn = [engine spawnWithEntrypoint:nil
                                          libraryURI:nil
                                        initialRoute:nil
                                      entrypointArgs:nil];
  XCTAssertNotNil(spawn);
  XCTAssertTrue([engine iosPlatformView] != nullptr);
  XCTAssertTrue([spawn iosPlatformView] != nullptr);
  std::shared_ptr<flutter::IOSContext> engine_context = [engine iosPlatformView]->GetIosContext();
  std::shared_ptr<flutter::IOSContext> spawn_context = [spawn iosPlatformView]->GetIosContext();
  XCTAssertEqual(engine_context, spawn_context);
  // If this assert fails it means we may be using the software.  For software rendering, this is
  // expected to be nullptr.
  XCTAssertTrue(engine_context->GetMainContext() != nullptr);
  XCTAssertEqual(engine_context->GetMainContext(), spawn_context->GetMainContext());
  [engine release];
}

- (void)testEnableSemanticsWhenFlutterViewAccessibilityDidCall {
  FlutterEngineSpy* engine = [[FlutterEngineSpy alloc] initWithName:@"foobar"];
  engine.ensureSemanticsEnabledCalled = NO;
  [engine flutterViewAccessibilityDidCall];
  XCTAssertTrue(engine.ensureSemanticsEnabledCalled);
  [engine release];
}

@end
