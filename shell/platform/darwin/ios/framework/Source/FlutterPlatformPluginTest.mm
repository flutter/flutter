// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

@interface FlutterPlatformPluginTest : XCTestCase
@end

@implementation FlutterPlatformPluginTest

- (void)testHasStrings {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  std::unique_ptr<fml::WeakPtrFactory<FlutterEngine>> _weakFactory =
      std::make_unique<fml::WeakPtrFactory<FlutterEngine>>(engine);
  FlutterPlatformPlugin* plugin =
      [[FlutterPlatformPlugin alloc] initWithEngine:_weakFactory->GetWeakPtr()];

  // Set some string to the pasteboard.
  __block bool calledSet = false;
  FlutterResult resultSet = ^(id result) {
    calledSet = true;
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.setClipboardData"
                                        arguments:@{@"text" : @"some string"}];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  XCTAssertEqual(calledSet, true);

  // Call hasStrings and expect it to be true.
  __block bool called = false;
  __block bool value;
  FlutterResult result = ^(id result) {
    called = true;
    value = result[@"value"];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [plugin handleMethodCall:methodCall result:result];

  XCTAssertEqual(called, true);
  XCTAssertEqual(value, true);
}

@end
