// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAppDelegate_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Test.h"

FLUTTER_ASSERT_ARC

@interface FlutterAppDelegateTest : XCTestCase
@end

@implementation FlutterAppDelegateTest

- (void)testLaunchUrl {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  FlutterViewController* viewController = OCMClassMock([FlutterViewController class]);
  FlutterEngine* engine = OCMClassMock([FlutterEngine class]);
  FlutterMethodChannel* navigationChannel = OCMClassMock([FlutterMethodChannel class]);
  OCMStub([engine navigationChannel]).andReturn(navigationChannel);
  OCMStub([viewController engine]).andReturn(engine);
  OCMStub([engine waitForFirstFrame:3.0 callback:([OCMArg invokeBlockWithArgs:@(NO), nil])]);
  appDelegate.rootFlutterViewControllerGetter = ^{
    return viewController;
  };
  NSURL* url = [NSURL URLWithString:@"http://example.com"];
  NSDictionary<UIApplicationOpenURLOptionsKey, id>* options = @{};
  BOOL result = [appDelegate application:[UIApplication sharedApplication]
                                 openURL:url
                                 options:options
                         infoPlistGetter:^NSDictionary*() {
                           return @{@"FlutterDeepLinkingEnabled" : @(YES)};
                         }];
  XCTAssertTrue(result);
  OCMVerify([navigationChannel invokeMethod:@"pushRoute" arguments:url.path]);
}

@end
