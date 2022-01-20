// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViewController.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/TestFlutterPlatformView.h"

#include "flutter/testing/testing.h"

namespace flutter::testing {

TEST(FlutterPlatformViewController, TestCreatePlatformViewNoMatchingViewType) {
  // Use id so we can access handleMethodCall method.
  id platformViewController = [[FlutterPlatformViewController alloc] init];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"FlutterPlatformViewMock"
                                        }];

  __block bool errored = false;
  FlutterResult result = ^(id result) {
    if ([result isKindOfClass:[FlutterError class]]) {
      errored = true;
    }
  };

  [platformViewController handleMethodCall:methodCall result:result];

  // We expect the call to error since no factories are registered.
  EXPECT_TRUE(errored);
}

TEST(FlutterPlatformViewController, TestRegisterPlatformViewFactoryAndCreate) {
  // Use id so we can access handleMethodCall method.
  id platformViewController = [[FlutterPlatformViewController alloc] init];

  TestFlutterPlatformViewFactory* factory = [TestFlutterPlatformViewFactory alloc];

  [platformViewController registerViewFactory:factory withId:@"MockPlatformView"];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"MockPlatformView"
                                        }];

  __block bool success = false;
  FlutterResult result = ^(id result) {
    // If a platform view is successfully created, the result is nil.
    if (result == nil) {
      success = true;
    }
  };
  [platformViewController handleMethodCall:methodCall result:result];

  EXPECT_TRUE(success);
}

TEST(FlutterPlatformViewController, TestCreateAndDispose) {
  // Use id so we can access handleMethodCall method.
  id platformViewController = [[FlutterPlatformViewController alloc] init];

  TestFlutterPlatformViewFactory* factory = [TestFlutterPlatformViewFactory alloc];

  [platformViewController registerViewFactory:factory withId:@"MockPlatformView"];

  FlutterMethodCall* methodCallOnCreate =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"MockPlatformView"
                                        }];

  __block bool created = false;
  FlutterResult resultOnCreate = ^(id result) {
    // If a platform view is successfully created, the result is nil.
    if (result == nil) {
      created = true;
    }
  };

  [platformViewController handleMethodCall:methodCallOnCreate result:resultOnCreate];

  FlutterMethodCall* methodCallOnDispose =
      [FlutterMethodCall methodCallWithMethodName:@"dispose"
                                        arguments:[NSNumber numberWithLongLong:2]];

  __block bool disposed = false;
  FlutterResult resultOnDispose = ^(id result) {
    // If a platform view is successfully created, the result is nil.
    if (result == nil) {
      disposed = true;
    }
  };

  [platformViewController handleMethodCall:methodCallOnDispose result:resultOnDispose];

  EXPECT_TRUE(created);
  EXPECT_TRUE(disposed);
}

TEST(FlutterPlatformViewController, TestDisposeOnMissingViewId) {
  // Use id so we can access handleMethodCall method.
  id platformViewController = [[FlutterPlatformViewController alloc] init];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"dispose"
                                        arguments:[NSNumber numberWithLongLong:20]];

  __block bool errored = false;
  FlutterResult result = ^(id result) {
    if ([result isKindOfClass:[FlutterError class]]) {
      errored = true;
    }
  };

  [platformViewController handleMethodCall:methodCall result:result];

  EXPECT_TRUE(errored);
}

}  // namespace flutter::testing
