// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

@interface FlutterPlatformPluginTest : XCTestCase
@end

@implementation FlutterPlatformPluginTest

- (void)testClipboardHasCorrectStrings {
  [UIPasteboard generalPasteboard].string = nil;
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  std::unique_ptr<fml::WeakPtrFactory<FlutterEngine>> _weakFactory =
      std::make_unique<fml::WeakPtrFactory<FlutterEngine>>(engine);
  FlutterPlatformPlugin* plugin =
      [[FlutterPlatformPlugin alloc] initWithEngine:_weakFactory->GetWeakPtr()];

  XCTestExpectation* setStringExpectation = [self expectationWithDescription:@"setString"];
  FlutterResult resultSet = ^(id result) {
    [setStringExpectation fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.setData"
                                        arguments:@{@"text" : @"some string"}];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  XCTestExpectation* hasStringsExpectation = [self expectationWithDescription:@"hasStrings"];
  FlutterResult result = ^(id result) {
    XCTAssertTrue([result[@"value"] boolValue]);
    [hasStringsExpectation fulfill];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [plugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  XCTestExpectation* getDataExpectation = [self expectationWithDescription:@"getData"];
  FlutterResult getDataResult = ^(id result) {
    XCTAssertEqualObjects(result[@"text"], @"some string");
    [getDataExpectation fulfill];
  };
  FlutterMethodCall* methodCallGetData =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.getData" arguments:@"text/plain"];
  [plugin handleMethodCall:methodCallGetData result:getDataResult];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testClipboardSetDataToNullDoNotCrash {
  [UIPasteboard generalPasteboard].string = nil;
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  std::unique_ptr<fml::WeakPtrFactory<FlutterEngine>> _weakFactory =
      std::make_unique<fml::WeakPtrFactory<FlutterEngine>>(engine);
  FlutterPlatformPlugin* plugin =
      [[FlutterPlatformPlugin alloc] initWithEngine:_weakFactory->GetWeakPtr()];

  XCTestExpectation* setStringExpectation = [self expectationWithDescription:@"setData"];
  FlutterResult resultSet = ^(id result) {
    [setStringExpectation fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.setData"
                                        arguments:@{@"text" : [NSNull null]}];
  [plugin handleMethodCall:methodCallSet result:resultSet];

  XCTestExpectation* getDataExpectation = [self expectationWithDescription:@"getData"];
  FlutterResult result = ^(id result) {
    XCTAssertEqualObjects(result[@"text"], @"null");
    [getDataExpectation fulfill];
  };
  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"Clipboard.getData"
                                                                    arguments:@"text/plain"];
  [plugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testPopSystemNavigator {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  UINavigationController* navigationController =
      [[UINavigationController alloc] initWithRootViewController:flutterViewController];
  UITabBarController* tabBarController = [[UITabBarController alloc] init];
  tabBarController.viewControllers = @[ navigationController ];
  std::unique_ptr<fml::WeakPtrFactory<FlutterEngine>> _weakFactory =
      std::make_unique<fml::WeakPtrFactory<FlutterEngine>>(engine);
  FlutterPlatformPlugin* plugin =
      [[FlutterPlatformPlugin alloc] initWithEngine:_weakFactory->GetWeakPtr()];

  id navigationControllerMock = OCMPartialMock(navigationController);
  OCMStub([navigationControllerMock popViewControllerAnimated:YES]);
  // Set some string to the pasteboard.
  XCTestExpectation* navigationPopCalled = [self expectationWithDescription:@"SystemNavigator.pop"];
  FlutterResult resultSet = ^(id result) {
    [navigationPopCalled fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"SystemNavigator.pop" arguments:@(YES)];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  OCMVerify([navigationControllerMock popViewControllerAnimated:YES]);
}

@end
