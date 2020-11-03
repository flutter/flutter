// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#include "flutter/testing/testing.h"

namespace flutter::testing {

// Returns a mock FlutterViewController that is able to work in environments
// without a real pasteboard.
id mockViewController(NSString* pasteboardString) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];

  // Mock pasteboard so that this test will work in environments without a
  // real pasteboard.
  id pasteboardMock = OCMClassMock([NSPasteboard class]);
  OCMExpect([pasteboardMock stringForType:[OCMArg any]]).andDo(^(NSInvocation* invocation) {
    NSString* returnValue = pasteboardString.length > 0 ? pasteboardString : nil;
    [invocation setReturnValue:&returnValue];
  });
  id viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock pasteboard]).andReturn(pasteboardMock);
  return viewControllerMock;
}

TEST(FlutterViewController, HasStringsWhenPasteboardEmpty) {
  // Mock FlutterViewController so that it behaves like the pasteboard is empty.
  id viewControllerMock = mockViewController(nil);

  // Call hasStrings and expect it to be false.
  __block bool calledAfterClear = false;
  __block bool valueAfterClear;
  FlutterResult resultAfterClear = ^(id result) {
    calledAfterClear = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    valueAfterClear = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCallAfterClear =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [viewControllerMock handleMethodCall:methodCallAfterClear result:resultAfterClear];
  EXPECT_TRUE(calledAfterClear);
  EXPECT_FALSE(valueAfterClear);
}

TEST(FlutterViewController, HasStringsWhenPasteboardFull) {
  // Mock FlutterViewController so that it behaves like the pasteboard has a
  // valid string.
  id viewControllerMock = mockViewController(@"some string");

  // Call hasStrings and expect it to be true.
  __block bool called = false;
  __block bool value;
  FlutterResult result = ^(id result) {
    called = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    value = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [viewControllerMock handleMethodCall:methodCall result:result];
  EXPECT_TRUE(called);
  EXPECT_TRUE(value);
}

}  // flutter::testing
