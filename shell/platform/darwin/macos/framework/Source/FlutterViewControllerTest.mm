// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#include "flutter/testing/testing.h"

namespace flutter::testing {

TEST(FlutterViewController, HasStringsWhenPasteboardEmpty) {
  // Mock FlutterViewController so that it behaves like the pasteboard is empty.
  id viewControllerMock = CreateMockViewController(nil);

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
  id viewControllerMock = CreateMockViewController(@"some string");

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
