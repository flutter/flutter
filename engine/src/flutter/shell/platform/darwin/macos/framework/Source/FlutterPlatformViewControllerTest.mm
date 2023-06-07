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

  NSDictionary* creationArgs = @{
    @"album" : @"スコットとリバース",
    @"releaseYear" : @2013,
    @"artists" : @[ @"Scott Murphy", @"Rivers Cuomo" ],
    @"playlist" : @[ @"おかしいやつ", @"ほどけていたんだ" ],
  };
  NSObject<FlutterMessageCodec>* codec = [factory createArgsCodec];
  FlutterStandardTypedData* creationArgsData =
      [FlutterStandardTypedData typedDataWithBytes:[codec encode:creationArgs]];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"MockPlatformView",
                                          @"params" : creationArgsData,
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

  // Verify PlatformView parameters are decoded correctly.
  TestFlutterPlatformView* view =
      (TestFlutterPlatformView*)[platformViewController platformViewWithID:2];
  ASSERT_TRUE(view != nil);
  ASSERT_TRUE(view.args != nil);

  // Verify string type.
  NSString* album = [view.args objectForKey:@"album"];
  EXPECT_TRUE([album isEqualToString:@"スコットとリバース"]);

  // Verify int type.
  NSNumber* releaseYear = [view.args objectForKey:@"releaseYear"];
  EXPECT_EQ(releaseYear.intValue, 2013);

  // Verify list/array types.
  NSArray* artists = [view.args objectForKey:@"artists"];
  ASSERT_TRUE(artists != nil);
  ASSERT_EQ(artists.count, 2ul);
  EXPECT_TRUE([artists[0] isEqualToString:@"Scott Murphy"]);
  EXPECT_TRUE([artists[1] isEqualToString:@"Rivers Cuomo"]);

  NSArray* playlist = [view.args objectForKey:@"playlist"];
  ASSERT_EQ(playlist.count, 2ul);
  EXPECT_TRUE([playlist[0] isEqualToString:@"おかしいやつ"]);
  EXPECT_TRUE([playlist[1] isEqualToString:@"ほどけていたんだ"]);
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
